import unittest
import tempfile
import shutil
import os
import sys

# Load antigravity-recent script dynamically
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from importlib.machinery import SourceFileLoader

script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../antigravity-recent.py'))
ag_recent = SourceFileLoader('ag_recent', script_path).load_module()

class TestAntigravityRecent(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        shutil.rmtree(self.test_dir)
        
    def test_format_relative_time(self):
        # 10 seconds ago
        self.assertEqual(ag_recent.format_relative_time(1000 * 1780000000, 1780000010), "10s ago")
        # 5 minutes ago
        self.assertEqual(ag_recent.format_relative_time(1000 * (1780000000 - 300), 1780000000), "5m ago")
        # 3 hours ago
        self.assertEqual(ag_recent.format_relative_time(1000 * (1780000000 - 10800), 1780000000), "3h ago")
        # 2 days ago
        self.assertEqual(ag_recent.format_relative_time(1000 * (1780000000 - 172800), 1780000000), "2d ago")
        # Future/negative time difference -> just now
        self.assertEqual(ag_recent.format_relative_time(1000 * (1780000000 + 10), 1780000000), "just now")

    def test_get_git_branch_standard(self):
        # Create a mock git dir
        project_dir = os.path.join(self.test_dir, 'proj')
        os.makedirs(project_dir)
        git_dir = os.path.join(project_dir, '.git')
        os.makedirs(git_dir)
        with open(os.path.join(git_dir, 'HEAD'), 'w') as f:
            f.write("ref: refs/heads/feature/cool-stuff\n")
            
        branch = ag_recent.get_git_branch(project_dir)
        self.assertEqual(branch, "feature/cool-stuff")

    def test_get_git_branch_detached(self):
        # Detached git HEAD
        project_dir = os.path.join(self.test_dir, 'proj_detached')
        os.makedirs(project_dir)
        git_dir = os.path.join(project_dir, '.git')
        os.makedirs(git_dir)
        with open(os.path.join(git_dir, 'HEAD'), 'w') as f:
            f.write("a1b2c3d4e5f6\n")
            
        branch = ag_recent.get_git_branch(project_dir)
        self.assertEqual(branch, "a1b2c3d")

    def test_get_git_branch_worktree(self):
        # Mock worktree setup (.git as file pointing to gitdir)
        project_dir = os.path.join(self.test_dir, 'proj_wt')
        os.makedirs(project_dir)
        
        real_git_dir = os.path.join(self.test_dir, 'real_git_location')
        os.makedirs(real_git_dir)
        
        with open(os.path.join(project_dir, '.git'), 'w') as f:
            f.write(f"gitdir: {real_git_dir}\n")
            
        with open(os.path.join(real_git_dir, 'HEAD'), 'w') as f:
            f.write("ref: refs/heads/worktree-branch\n")
            
        branch = ag_recent.get_git_branch(project_dir)
        self.assertEqual(branch, "worktree-branch")

    def test_parse_history(self):
        # Create dummy directories in temp directory
        proj1 = os.path.join(self.test_dir, 'proj1')
        proj2 = os.path.join(self.test_dir, 'proj2')
        proj3 = os.path.join(self.test_dir, 'proj3')
        os.makedirs(proj1)
        os.makedirs(proj2)
        # Note: proj3 is not created (missing/deleted)
        
        history_file = os.path.join(self.test_dir, 'history.jsonl')
        with open(history_file, 'w') as f:
            f.write(f'{{"workspace": "{proj1}", "timestamp": 1780000000000}}\n')
            f.write(f'{{"workspace": "{proj2}", "timestamp": 1780000100000}}\n')
            f.write(f'{{"workspace": "{proj3}", "timestamp": 1780000200000}}\n') # Missing directory
            f.write(f'{{"workspace": "/home/aaron", "timestamp": 1780000300000}}\n') # Home directory (should be excluded)
            
        parsed = ag_recent.parse_history(history_file, '/home/aaron')
        
        # Should return sorted list of existing projects: proj2 then proj1
        self.assertEqual(len(parsed), 2)
        self.assertEqual(parsed[0][0], proj2)
        self.assertEqual(parsed[1][0], proj1)

if __name__ == '__main__':
    unittest.main()
