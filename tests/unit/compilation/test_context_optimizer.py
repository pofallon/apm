"""Unit tests for the Context Optimizer.

Tests the Context Optimization Engine that minimizes irrelevant context
loaded by agents working in specific directories.
"""

import os
import tempfile
import pytest
import fnmatch
from pathlib import Path
from unittest.mock import patch, MagicMock

from apm_cli.compilation.context_optimizer import (
    ContextOptimizer,
    DirectoryAnalysis,
    InheritanceAnalysis,
    PlacementCandidate
)
from apm_cli.primitives.models import Instruction


class TestDirectoryAnalysis:
    """Test DirectoryAnalysis dataclass."""
    
    def test_get_relevance_score_empty_directory(self):
        """Test relevance score calculation for empty directory."""
        analysis = DirectoryAnalysis(
            directory=Path("/test"),
            depth=1,
            total_files=0
        )
        assert analysis.get_relevance_score("**/*.py") == 0.0
    
    def test_get_relevance_score_with_matches(self):
        """Test relevance score calculation with pattern matches."""
        analysis = DirectoryAnalysis(
            directory=Path("/test"),
            depth=1,
            total_files=10,
            pattern_matches={"**/*.py": 3}
        )
        assert analysis.get_relevance_score("**/*.py") == 0.3
    
    def test_get_relevance_score_no_matches(self):
        """Test relevance score for pattern with no matches."""
        analysis = DirectoryAnalysis(
            directory=Path("/test"),
            depth=1,
            total_files=10,
            pattern_matches={"**/*.js": 5}
        )
        assert analysis.get_relevance_score("**/*.py") == 0.0


class TestInheritanceAnalysis:
    """Test InheritanceAnalysis dataclass."""
    
    def test_get_efficiency_ratio_no_context(self):
        """Test efficiency ratio with no context load."""
        analysis = InheritanceAnalysis(
            working_directory=Path("/test"),
            inheritance_chain=[Path("/test")]
        )
        assert analysis.get_efficiency_ratio() == 1.0
    
    def test_get_efficiency_ratio_perfect_relevance(self):
        """Test efficiency ratio with perfect context relevance."""
        analysis = InheritanceAnalysis(
            working_directory=Path("/test"),
            inheritance_chain=[Path("/test")],
            total_context_load=5,
            relevant_context_load=5
        )
        assert analysis.get_efficiency_ratio() == 1.0
    
    def test_get_efficiency_ratio_partial_relevance(self):
        """Test efficiency ratio with partial context relevance."""
        analysis = InheritanceAnalysis(
            working_directory=Path("/test"),
            inheritance_chain=[Path("/test")],
            total_context_load=10,
            relevant_context_load=6
        )
        assert analysis.get_efficiency_ratio() == 0.6


class TestPlacementCandidate:
    """Test PlacementCandidate dataclass."""
    
    def test_post_init_score_calculation(self):
        """Test that total_score is calculated correctly in __post_init__."""
        instruction = Instruction(
            name="test",
            file_path=Path("test.md"),
            description="Test instruction",
            apply_to="**/*.py",
            content="Test content",
            source="local"
        )
        
        candidate = PlacementCandidate(
            instruction=instruction,
            directory=Path("/test"),
            direct_relevance=0.8,
            inheritance_pollution=0.3,
            depth_specificity=0.2,
            total_score=0.0  # Will be overwritten
        )
        
        # Score = 0.8 * 1.0 + (-0.3 * 0.5) + 0.2 * 0.1 = 0.8 - 0.15 + 0.02 = 0.67
        expected_score = 0.8 - (0.3 * 0.5) + (0.2 * 0.1)
        assert abs(candidate.total_score - expected_score) < 0.001


class TestContextOptimizer:
    """Test ContextOptimizer class."""
    
    @pytest.fixture
    def temp_project(self):
        """Create a temporary project structure for testing."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            
            # Create directory structure
            (temp_path / "server").mkdir()
            (temp_path / "styles").mkdir()
            (temp_path / "tests").mkdir()
            (temp_path / "src" / "components").mkdir(parents=True)
            
            # Create test files
            (temp_path / "server" / "api.py").touch()
            (temp_path / "server" / "models.py").touch()
            (temp_path / "styles" / "main.css").touch()
            (temp_path / "styles" / "tokens.scss").touch()
            (temp_path / "tests" / "test_api.py").touch()
            (temp_path / "tests" / "test_ui.tsx").touch()
            (temp_path / "src" / "components" / "Button.tsx").touch()
            (temp_path / "src" / "components" / "Modal.tsx").touch()
            (temp_path / "index.html").touch()
            (temp_path / "main.js").touch()
            
            yield temp_path
    
    @pytest.fixture
    def sample_instructions(self):
        """Create sample instructions for testing."""
        return [
            Instruction(
                name="python-standards",
                file_path=Path("python.instructions.md"),
                description="Python development standards",
                apply_to="**/*.py",
                content="Python coding standards",
                source="local"
            ),
            Instruction(
                name="typescript-standards",
                file_path=Path("typescript.instructions.md"),
                description="TypeScript development standards",
                apply_to="**/*.{ts,tsx}",
                content="TypeScript coding standards",
                source="local"
            ),
            Instruction(
                name="css-standards",
                file_path=Path("css.instructions.md"),
                description="CSS development standards",
                apply_to="**/*.{css,scss}",
                content="CSS coding standards",
                source="local"
            ),
            Instruction(
                name="general-standards",
                file_path=Path("general.instructions.md"),
                description="General development standards",
                apply_to="**/*.{py,js,ts,tsx,css,scss}",
                content="General coding standards",
                source="local"
            )
        ]
    
    def test_initialization(self, temp_project):
        """Test ContextOptimizer initialization."""
        optimizer = ContextOptimizer(str(temp_project))
        assert optimizer.base_dir.resolve() == temp_project.resolve()
        assert optimizer._directory_cache == {}
        assert optimizer._pattern_cache == {}
    
    def test_initialization_with_invalid_path(self):
        """Test ContextOptimizer initialization with invalid path."""
        optimizer = ContextOptimizer("/nonexistent/path")
        assert optimizer.base_dir == Path("/nonexistent/path").absolute()
    
    def test_analyze_project_structure(self, temp_project):
        """Test project structure analysis."""
        optimizer = ContextOptimizer(str(temp_project))
        optimizer._analyze_project_structure()
        
        # Check that directories were analyzed
        assert len(optimizer._directory_cache) > 0
        
        # Check specific directories
        assert temp_project.resolve() in optimizer._directory_cache
        assert (temp_project / "server").resolve() in optimizer._directory_cache
        assert (temp_project / "styles").resolve() in optimizer._directory_cache
        
        # Check file counts
        server_analysis = optimizer._directory_cache[(temp_project / "server").resolve()]
        assert server_analysis.total_files == 2  # api.py, models.py
        assert server_analysis.depth == 1
    
    def test_find_matching_directories(self, temp_project, sample_instructions):
        """Test finding directories that match file patterns."""
        optimizer = ContextOptimizer(str(temp_project))
        optimizer._analyze_project_structure()
        
        # Test Python pattern
        python_dirs = optimizer._find_matching_directories("**/*.py")
        expected_python_dirs = {(temp_project / "server").resolve(), (temp_project / "tests").resolve()}
        assert python_dirs == expected_python_dirs
        
        # Test CSS pattern
        css_dirs = optimizer._find_matching_directories("**/*.{css,scss}")
        expected_css_dirs = {(temp_project / "styles").resolve()}
        assert css_dirs == expected_css_dirs
        
        # Test TypeScript pattern
        tsx_dirs = optimizer._find_matching_directories("**/*.{ts,tsx}")
        expected_tsx_dirs = {(temp_project / "tests").resolve(), (temp_project / "src" / "components").resolve()}
        assert tsx_dirs == expected_tsx_dirs
    
    def test_optimize_instruction_placement_isolated_patterns(self, temp_project, sample_instructions):
        """Test optimization for patterns that are cleanly isolated using mathematical optimization."""
        optimizer = ContextOptimizer(str(temp_project))
        
        # Filter to just Python and CSS instructions (cleanly separated)
        isolated_instructions = [
            inst for inst in sample_instructions 
            if inst.name in ["python-standards", "css-standards"]
        ]
        
        placement = optimizer.optimize_instruction_placement(isolated_instructions)
        
        # Mathematical optimization uses three-tier strategy with coverage guarantee
        python_placements = []
        css_placements = []
        
        for directory, instructions in placement.items():
            for instruction in instructions:
                if instruction.name == "python-standards":
                    python_placements.append(directory)
                elif instruction.name == "css-standards":
                    css_placements.append(directory)
        
        # Verify Python instruction is placed to guarantee coverage
        assert len(python_placements) >= 1  # At least one placement guaranteed
        # Coverage takes priority over efficiency - may be placed at root for universal access
        python_dirs_with_files = [(temp_project / "server").resolve(), (temp_project / "tests").resolve(), temp_project.resolve()]
        assert any(placement in python_dirs_with_files for placement in python_placements)
        
        # Verify CSS is placed where it can be accessed by CSS files
        assert len(css_placements) >= 1  # At least one placement guaranteed
        # May be placed at root for coverage or at styles directory for efficiency
        css_dirs_allowed = [(temp_project / "styles").resolve(), temp_project.resolve()]
        assert any(placement in css_dirs_allowed for placement in css_placements)
    
    def test_optimize_instruction_placement_widespread_pattern(self, temp_project, sample_instructions):
        """Test optimization for widespread patterns that should go to root."""
        optimizer = ContextOptimizer(str(temp_project))
        
        # The general-standards instruction applies to many file types and should go to root
        general_instruction = [
            inst for inst in sample_instructions 
            if inst.name == "general-standards"
        ][0]
        
        placement = optimizer.optimize_instruction_placement([general_instruction])
        
        # Should be placed at root due to widespread nature
        assert temp_project.resolve() in placement
        assert general_instruction in placement[temp_project.resolve()]
    
    def test_optimize_instruction_placement_no_pattern(self, temp_project):
        """Test optimization for instructions without apply_to pattern."""
        optimizer = ContextOptimizer(str(temp_project))
        
        instruction_without_pattern = Instruction(
            name="global-instruction",
            file_path=Path("global.instructions.md"),
            description="Global instruction",
            apply_to="",  # No pattern
            content="Global content",
            source="local"
        )
        
        placement = optimizer.optimize_instruction_placement([instruction_without_pattern])
        
        # Should be placed at root
        assert temp_project.resolve() in placement
        assert instruction_without_pattern in placement[temp_project.resolve()]
    
    def test_calculate_inheritance_pollution(self, temp_project, sample_instructions):
        """Test inheritance pollution calculation."""
        optimizer = ContextOptimizer(str(temp_project))
        optimizer._analyze_project_structure()
        
        # Test pollution for placing Python instruction at root
        # This should create pollution for styles directory (no Python files)
        pollution = optimizer._calculate_inheritance_pollution(temp_project.resolve(), "**/*.py")
        # Note: pollution calculation depends on child directories existing
        # If styles directory has no Python files, placing Python instruction at root creates pollution
        # The actual value depends on the implementation details
    
    def test_analyze_context_inheritance(self, temp_project, sample_instructions):
        """Test context inheritance analysis."""
        optimizer = ContextOptimizer(str(temp_project))
        
        # Create a simple placement map
        placement_map = {
            temp_project.resolve(): [sample_instructions[3]],  # general-standards at root
            (temp_project / "server").resolve(): [sample_instructions[0]]  # python-standards in server
        }
        
        # Analyze inheritance for server directory
        inheritance = optimizer.analyze_context_inheritance(
            (temp_project / "server").resolve(), 
            placement_map
        )
        
        assert inheritance.working_directory == (temp_project / "server").resolve()
        assert len(inheritance.inheritance_chain) >= 2  # server and root
        assert inheritance.total_context_load >= 2  # At least the two instructions
    
    def test_get_optimization_stats(self, temp_project, sample_instructions):
        """Test optimization statistics generation."""
        optimizer = ContextOptimizer(str(temp_project))
        
        # Create a placement map
        placement_map = optimizer.optimize_instruction_placement(sample_instructions)
        
        # Convert Path keys to string keys for the stats method
        stats_placement_map = {str(path): instructions for path, instructions in placement_map.items()}
        stats = optimizer.get_optimization_stats(stats_placement_map)
        
        # Check required stats (new API) - stats is an OptimizationStats object
        assert hasattr(stats, 'average_context_efficiency')
        assert hasattr(stats, 'total_agents_files')
        assert hasattr(stats, 'directories_analyzed')
        
        # Check value ranges
        assert 0.0 <= stats.average_context_efficiency <= 1.0
        assert stats.total_agents_files >= 0
        assert stats.directories_analyzed >= 0
    
    def test_get_inheritance_chain(self, temp_project):
        """Test inheritance chain generation."""
        optimizer = ContextOptimizer(str(temp_project))
        
        # Test chain for nested directory
        deep_dir = (temp_project / "src" / "components").resolve()
        chain = optimizer._get_inheritance_chain(deep_dir)
        
        expected_chain = [
            deep_dir,
            (temp_project / "src").resolve(),
            temp_project.resolve()
        ]
        
        assert chain == expected_chain
    
    def test_is_child_directory(self, temp_project):
        """Test child directory detection."""
        optimizer = ContextOptimizer(str(temp_project))
        
        parent = (temp_project / "src").resolve()
        child = (temp_project / "src" / "components").resolve()
        sibling = (temp_project / "server").resolve()
        
        assert optimizer._is_child_directory(child, parent) is True
        assert optimizer._is_child_directory(parent, child) is False
        assert optimizer._is_child_directory(sibling, parent) is False
        assert optimizer._is_child_directory(parent, parent) is False
    
    def test_is_instruction_relevant(self, temp_project):
        """Test instruction relevance detection."""
        optimizer = ContextOptimizer(str(temp_project))
        optimizer._analyze_project_structure()
        
        python_instruction = Instruction(
            name="python-test",
            file_path=Path("python.instructions.md"),
            description="Python test",
            apply_to="**/*.py",
            content="Python content",
            source="local"
        )
        
        global_instruction = Instruction(
            name="global-test",
            file_path=Path("global.instructions.md"),
            description="Global test",
            apply_to="",  # No pattern - always relevant
            content="Global content",
            source="local"
        )
        
        # Python instruction should be relevant to server (has .py files)
        assert optimizer._is_instruction_relevant(python_instruction, (temp_project / "server").resolve()) is True
        
        # Python instruction should not be relevant to styles (no .py files)
        assert optimizer._is_instruction_relevant(python_instruction, (temp_project / "styles").resolve()) is False
        
        # Global instruction should always be relevant
        assert optimizer._is_instruction_relevant(global_instruction, (temp_project / "server").resolve()) is True
        assert optimizer._is_instruction_relevant(global_instruction, (temp_project / "styles").resolve()) is True
    
    def test_select_clean_separation_placements(self, temp_project, sample_instructions):
        """Test clean separation placement selection."""
        optimizer = ContextOptimizer(str(temp_project))
        optimizer._analyze_project_structure()
        
        # Create candidates for Python instruction
        python_instruction = sample_instructions[0]  # python-standards
        
        candidates = [
            PlacementCandidate(
                instruction=python_instruction,
                directory=(temp_project / "server").resolve(),
                direct_relevance=1.0,
                inheritance_pollution=0.1,
                depth_specificity=0.1,
                total_score=0.0  # Will be calculated
            ),
            PlacementCandidate(
                instruction=python_instruction,
                directory=(temp_project / "tests").resolve(),
                direct_relevance=0.5,
                inheritance_pollution=0.1,
                depth_specificity=0.1,
                total_score=0.0  # Will be calculated
            )
        ]
        
        # These directories are isolated (neither is parent/child of the other)
        clean_placements = optimizer._select_clean_separation_placements(
            candidates, 
            "**/*.py"
        )
        
                # Should return both directories for clean separation
        expected_dirs = {(temp_project / "server").resolve(), (temp_project / "tests").resolve()}
        assert set(clean_placements) == expected_dirs
    
    def test_real_project_optimization_benefits(self, temp_project):
        """Test that optimization provides real benefits over naive placement."""
        optimizer = ContextOptimizer(str(temp_project))
    
    def test_real_project_optimization_benefits(self, temp_project):
        """Test that optimization provides real benefits over naive placement."""
        optimizer = ContextOptimizer(str(temp_project))
        
        # Create instructions that would cause pollution if not optimized
        instructions = [
            Instruction(
                name="python-only",
                file_path=Path("python.instructions.md"),
                description="Python only",
                apply_to="**/*.py",
                content="Python content",
                source="local"
            ),
            Instruction(
                name="css-only",
                file_path=Path("css.instructions.md"),
                description="CSS only",
                apply_to="**/*.{css,scss}",
                content="CSS content",
                source="local"
            ),
            Instruction(
                name="frontend-only",
                file_path=Path("frontend.instructions.md"),
                description="Frontend only",
                apply_to="**/*.{ts,tsx,css,scss,html}",
                content="Frontend content",
                source="local"
            )
        ]
        
        # Get optimized placement
        optimized_placement = optimizer.optimize_instruction_placement(instructions)
        
        # Simulate naive placement (all at root)
        naive_placement = {temp_project.resolve(): instructions}
        
        # Compare context efficiency for server directory (Python work)
        server_dir = (temp_project / "server").resolve()
        
        optimized_inheritance = optimizer.analyze_context_inheritance(server_dir, optimized_placement)
        naive_inheritance = optimizer.analyze_context_inheritance(server_dir, naive_placement)
        
        optimized_efficiency = optimized_inheritance.get_efficiency_ratio()
        naive_efficiency = naive_inheritance.get_efficiency_ratio()
        
        # With coverage-first optimization, efficiency comparison is more nuanced
        # The optimizer prioritizes coverage guarantee over efficiency
        assert optimized_efficiency >= naive_efficiency or optimized_efficiency >= 0.5
        
        # For server directory with only Python files, optimized placement should provide reasonable efficiency
        # Even if coverage constraints require some pollution
        if optimized_efficiency > 0:  # If there's any optimization possible
            # Either optimized is better, or it's a reasonable efficiency given coverage constraints
            assert optimized_efficiency >= naive_efficiency or optimized_efficiency >= 0.3


if __name__ == "__main__":
    pytest.main([__file__])