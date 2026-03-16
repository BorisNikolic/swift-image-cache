#!/usr/bin/env python3
#
# Git command to transform staged files according to a command that accepts file
# content on stdin and produces output on stdout.
#
# Usage: git-format-staged [OPTION]... [FILE]...
# Example: git-format-staged --formatter 'prettier --stdin-filepath "{}"' '*.js'
#
# Original author: Jesse Hallett <jesse@sitr.us>

from __future__ import print_function
import argparse
from fnmatch import fnmatch
from gettext import gettext as _
import os
import re
import subprocess
import sys

VERSION = '1.0.0'
PROG = sys.argv[0]

def info(msg):
    print(msg, file=sys.stdout)

def warn(msg):
    print('{}: warning: {}'.format(PROG, msg), file=sys.stderr)

def fatal(msg):
    print('{}: error: {}'.format(PROG, msg), file=sys.stderr)
    exit(1)

def format_staged_files(file_patterns, formatter, git_root, update_working_tree=True, write=True, verbose=False):
    try:
        output = subprocess.check_output([
            'git', 'diff-index',
            '--cached',
            '--diff-filter=AM',
            '--no-renames',
            'HEAD'
            ])
        for line in output.splitlines():
            entry = parse_diff(line.decode('utf-8'))
            entry_path = normalize_path(entry['src_path'], relative_to=git_root)
            if entry['dst_mode'] == '120000':
                continue
            if not (matches_some_path(file_patterns, entry_path)):
                continue
            if format_file_in_index(formatter, entry, update_working_tree=update_working_tree, write=write, verbose=verbose):
                info('Reformatted {} with {}'.format(entry['src_path'], formatter))
    except Exception as err:
        fatal(str(err))

def format_file_in_index(formatter, diff_entry, update_working_tree=True, write=True, verbose=False):
    orig_hash = diff_entry['dst_hash']
    new_hash = format_object(formatter, orig_hash, diff_entry['src_path'], verbose=verbose)

    if not write or new_hash == orig_hash:
        return None

    if object_is_empty(new_hash):
        return None

    replace_file_in_index(diff_entry, new_hash)

    if update_working_tree:
        try:
            patch_working_file(diff_entry['src_path'], orig_hash, new_hash)
        except Exception as err:
            warn(str(err))

    return new_hash

file_path_placeholder = re.compile(r'\{\}')

def format_object(formatter, object_hash, file_path, verbose=False):
    get_content = subprocess.Popen(
            ['git', 'cat-file', '-p', object_hash],
            stdout=subprocess.PIPE
            )
    command = re.sub(file_path_placeholder, file_path, formatter)
    if verbose:
        info(command)
    format_content = subprocess.Popen(
            command,
            shell=True,
            stdin=get_content.stdout,
            stdout=subprocess.PIPE
            )
    write_object = subprocess.Popen(
            ['git', 'hash-object', '-w', '--stdin'],
            stdin=format_content.stdout,
            stdout=subprocess.PIPE
            )

    get_content.stdout.close()
    format_content.stdout.close()

    if get_content.wait() != 0:
        raise ValueError('unable to read file content from object database: ' + object_hash)

    if format_content.wait() != 0:
        raise Exception('formatter exited with non-zero status')

    new_hash, err = write_object.communicate()

    if write_object.returncode != 0:
        raise Exception('unable to write formatted content to object database')

    return new_hash.decode('utf-8').rstrip()

def object_is_empty(object_hash):
    get_content = subprocess.Popen(
            ['git', 'cat-file', '-p', object_hash],
            stdout=subprocess.PIPE
        )
    content, err = get_content.communicate()

    if get_content.returncode != 0:
        raise Exception('unable to verify content of formatted object')

    return not content

def replace_file_in_index(diff_entry, new_object_hash):
    subprocess.check_call(['git', 'update-index',
        '--cacheinfo', '{},{},{}'.format(
            diff_entry['dst_mode'],
            new_object_hash,
            diff_entry['src_path']
            )])

def patch_working_file(path, orig_object_hash, new_object_hash):
    patch = subprocess.check_output(
            ['git', 'diff', '--no-ext-diff', '--color=never', orig_object_hash, new_object_hash]
            )

    patch_b = patch.replace(orig_object_hash.encode(), path.encode()).replace(new_object_hash.encode(), path.encode())

    apply_patch = subprocess.Popen(
            ['git', 'apply', '-'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
            )

    output, err = apply_patch.communicate(input=patch_b)

    if apply_patch.returncode != 0:
        raise Exception('could not apply formatting changes to working tree file {}'.format(path))

diff_pat = re.compile(r'^:(\d+) (\d+) ([a-f0-9]+) ([a-f0-9]+) ([A-Z])(\d+)?\t([^\t]+)(?:\t([^\t]+))?$')

def parse_diff(diff):
    m = diff_pat.match(diff)
    if not m:
        raise ValueError('Failed to parse diff-index line: ' + diff)
    return {
            'src_mode': unless_zeroed(m.group(1)),
            'dst_mode': unless_zeroed(m.group(2)),
            'src_hash': unless_zeroed(m.group(3)),
            'dst_hash': unless_zeroed(m.group(4)),
            'status': m.group(5),
            'score': int(m.group(6)) if m.group(6) else None,
            'src_path': m.group(7),
            'dst_path': m.group(8)
            }

zeroed_pat = re.compile(r'^0+$')

def unless_zeroed(s):
    return s if not zeroed_pat.match(s) else None

def get_git_root():
    return subprocess.check_output(
            ['git', 'rev-parse', '--show-toplevel']
            ).decode('utf-8').rstrip()

def normalize_path(p, relative_to=None):
    return os.path.abspath(
            os.path.join(relative_to, p) if relative_to else p
            )

def matches_some_path(patterns, target):
    is_match = False
    for signed_pattern in patterns:
        (is_pattern_positive, pattern) = from_signed_pattern(signed_pattern)
        if fnmatch(target, normalize_path(pattern)):
            is_match = is_pattern_positive
    return is_match

def from_signed_pattern(pattern):
    if pattern[0] == '!':
        return (False, pattern[1:])
    else:
        return (True, pattern)

class CustomArgumentParser(argparse.ArgumentParser):
    def parse_args(self, args=None, namespace=None):
        args, argv = self.parse_known_args(args, namespace)
        if argv:
            msg = argparse._(
                    'unrecognized arguments: %s. Do you need to quote your formatter command?'
                    )
            self.error(msg % ' '.join(argv))
        return args

if __name__ == '__main__':
    parser = CustomArgumentParser(
            description='Transform staged files using a formatting command that accepts content via stdin and produces a result via stdout.',
            epilog='Example: %(prog)s --formatter "prettier --stdin-filepath \'{}\'" "src/*.js" "test/*.js"'
            )
    parser.add_argument(
            '--formatter', '-f',
            required=True,
            help='Shell command to format files, will run once per file.'
            )
    parser.add_argument(
            '--no-update-working-tree',
            action='store_true',
            help='Do not apply formatting changes to working tree files.'
            )
    parser.add_argument(
            '--no-write',
            action='store_true',
            help='Prevents modifying staged or working tree files.'
            )
    parser.add_argument(
            '--version',
            action='version',
            version='%(prog)s version {}'.format(VERSION)
            )
    parser.add_argument(
            '--verbose',
            help='Show the formatting commands that are running',
            action='store_true'
            )
    parser.add_argument(
            'files',
            nargs='+',
            help='Patterns that specify files to format.'
            )
    args = parser.parse_args()
    files = vars(args)['files']
    format_staged_files(
            file_patterns=files,
            formatter=vars(args)['formatter'],
            git_root=get_git_root(),
            update_working_tree=not vars(args)['no_update_working_tree'],
            write=not vars(args)['no_write'],
            verbose=vars(args)['verbose']
            )
