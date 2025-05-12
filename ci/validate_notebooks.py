#!/usr/bin/env python3
"""
Script to validate Jupyter notebooks in CI environment.
This script checks the structure and syntax of notebooks without requiring full execution.
"""

import os
import sys
import json
import ast
import tempfile
import subprocess
from pathlib import Path


def setup_mock_modules():
    """Create mock modules for imports that aren't available in the CI environment"""
    # Create a mock pyspark module for syntax validation without execution
    sys.modules["pyspark"] = type("MockPySparkModule", (), {})
    sys.modules["pyspark.sql"] = type("MockPySparkSQL", (), {})
    class MockFunctions:
        @staticmethod
        def current_timestamp():
            pass
    sys.modules["pyspark.sql.functions"] = MockFunctions


def validate_notebook_json(notebook_path):
    """Verify the notebook is valid JSON"""
    try:
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook_content = json.load(f)
        return True
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON in {notebook_path}: {e}")
        return False


def validate_notebook_syntax(notebook_path):
    """Extract Python code from notebook and check syntax"""
    try:
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook_content = json.load(f)
            
        # Create a temporary Python file for syntax checking
        with tempfile.NamedTemporaryFile(suffix=".py", delete=False) as temp_file:
            for cell in notebook_content.get("cells", []):
                if cell.get("cell_type") == "code":
                    source = "".join(cell.get("source", []))
                    temp_file.write(source.encode('utf-8'))
                    temp_file.write(b"\n\n")
            
            temp_filename = temp_file.name
        
        # Check syntax of the generated Python file
        try:
            ast.parse(open(temp_filename, "rb").read())
            os.unlink(temp_filename)
            return True
        except SyntaxError as e:
            print(f"ERROR: Python syntax error in {notebook_path}: {e}")
            os.unlink(temp_filename)
            return False
    except Exception as e:
        print(f"ERROR: Failed to validate notebook syntax in {notebook_path}: {e}")
        return False


def validate_notebook_imports(notebook_path):
    """Check that all imports would work with mock modules"""
    try:
        setup_mock_modules()
        
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook_content = json.load(f)
            
        all_code = ""
        for cell in notebook_content.get("cells", []):
            if cell.get("cell_type") == "code":
                source = "".join(cell.get("source", []))
                all_code += source + "\n\n"
                
        # Extract import statements
        import_lines = [line for line in all_code.split("\n") 
                       if line.strip().startswith(("import ", "from "))]
        
        # Create a temp file with just the imports
        with tempfile.NamedTemporaryFile(suffix=".py", delete=False) as temp_file:
            temp_file.write("\n".join(import_lines).encode('utf-8'))
            temp_filename = temp_file.name
        
        # Try to execute just the imports
        result = subprocess.run(
            [sys.executable, temp_filename],
            capture_output=True,
            text=True
        )
        os.unlink(temp_filename)
        
        if result.returncode != 0:
            print(f"ERROR: Import validation failed for {notebook_path}:")
            print(result.stderr)
            return False
            
        return True
    except Exception as e:
        print(f"ERROR: Failed to validate notebook imports in {notebook_path}: {e}")
        return False


def main():
    """Main function to validate all notebooks in the repo"""
    notebook_dir = Path("notebooks")
    if not notebook_dir.exists():
        print(f"ERROR: Notebook directory {notebook_dir} not found")
        sys.exit(1)
        
    notebooks = list(notebook_dir.glob("*.ipynb"))
    if not notebooks:
        print(f"WARNING: No notebooks found in {notebook_dir}")
        sys.exit(0)
        
    success = True
    for notebook_path in notebooks:
        print(f"Validating notebook: {notebook_path}")
        
        # Check JSON structure
        if not validate_notebook_json(notebook_path):
            success = False
            continue
            
        # Check Python syntax without execution
        if not validate_notebook_syntax(notebook_path):
            success = False
            continue
            
        print(f"✓ Notebook {notebook_path} validated successfully")
        
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
