# Context Guide

Context components are the configurable tools that deploy proven prompt engineering and context engineering techniques. APM implements these as the core building blocks for reliable, reusable AI development workflows.

## How Context Components Work

APM implements Context - the configurable tools that deploy prompt engineering and context engineering techniques to transform unreliable AI interactions into engineered systems.

### 🏗️ Initialize a project with AI-Native structure

```bash
apm init my-project  # Creates complete Context scaffolding + apm.yml
```

### ⚙️ Generated Project Structure

```yaml
my-project/
├── apm.yml              # Project configuration and script definitions
└── .apm/
    ├── chatmodes/       # Role-based AI expertise with tool boundaries
    │   ├── backend-dev.chatmode.md     # API development specialist
    │   └── frontend-dev.chatmode.md    # UI development specialist
    ├── instructions/    # Targeted guidance by file type and domain  
    │   ├── security.instructions.md    # applyTo: "auth/**"
    │   └── testing.instructions.md     # applyTo: "**/*test*"
    ├── prompts/         # Reusable agent workflows
    │   ├── code-review.prompt.md       # Systematic review process
    │   └── feature-spec.prompt.md      # Spec-first development
    └── context/         # Optimized information retrieval
        └── architecture.context.md     # Project patterns and decisions
```

### 🔄 Context Optimization & Compilation

APM's distributed compilation system solves the **hierarchical coverage problem** - ensuring AI agents can access all applicable instructions through hierarchical inheritance while minimizing context pollution.

#### The Core Problem: Coverage vs. Pollution Trade-off

The fundamental challenge is ensuring that **every file can access instructions that apply to it** while minimizing irrelevant context pollution. This requires balancing two competing objectives:

1. **Coverage Guarantee**: No file should lose access to applicable instructions
2. **Context Efficiency**: Minimize irrelevant instructions agents inherit

**Critical Insight**: These objectives are often in conflict. Perfect coverage may require placing instructions higher in the directory tree, creating some pollution as an acceptable trade-off.

#### The Hierarchical Inheritance Principle

APM respects the hierarchical reading model where agents inherit instructions from parent directories:

```
corporate-website/
├── AGENTS.md                    # Root level - inherited by ALL subdirectories
├── src/
│   ├── AGENTS.md               # Inherited by src/components/, src/utils/, etc.
│   └── components/
│       ├── AGENTS.md           # Only inherited by files in components/
│       └── ContactForm.tsx     # Inherits: root + src + components
```

**Coverage Violation Example** (what APM prevents):
- `design-standards.instructions.md` affects `**/*.scss` files
- If placed in `frontend/components/AGENTS.md`
- Then `src/components/ContactForm.scss` cannot access design standards
- **Result**: Data loss and inconsistent behavior

#### Mathematical Foundation

APM treats instruction placement as a **coverage-constrained optimization problem**:

```
Objective: minimize Σ(context_pollution × directory_weight)
Constraints: ∀file_matching_pattern → can_inherit_instruction
Variables: placement_matrix ∈ {0,1}
Algorithm: Three-tier strategy with hierarchical coverage verification
```

**Context Efficiency Formula**:
```
Context_Efficiency = Σ(Relevant_Instructions_Per_Directory) / Σ(Total_Instructions_Inherited_Per_Directory)

Where for each directory:
- Relevant_Instructions = patterns matching files recursively in that directory
- Total_Instructions_Inherited = all instructions inherited from AGENTS.md chain
- Weighted by number of files in directory
```

#### Three-Tier Placement Algorithm with Coverage Guarantee

APM uses **distribution scoring** with **hierarchical coverage verification**:

**Distribution Score** = `matching_directories / total_directories`

1. **Single Point Placement** (< 0.3 distribution)
   - **Strategy**: Place at most specific directory that provides complete coverage
   - **Example**: `docs/**/*.md` → `docs/AGENTS.md` (if docs/ contains all matching files)
   - **Coverage**: Perfect - only affects intended directory tree

2. **Selective Multi-Placement** (0.3-0.7 distribution) **with Coverage Verification**
   - **Strategy**: Place at high-relevance directories IF they provide complete coverage
   - **Coverage Check**: Verify all matching files can inherit the instruction
   - **Fallback**: If coverage gaps exist, escalate to root placement
   - **Example**: `**/*.tsx` matches `src/components/` and `frontend/components/`
     - If both branches covered: place in both directories
     - If coverage gaps: place at root for universal access

3. **Distributed Placement** (> 0.7 distribution)
   - **Strategy**: Place at root for universal inheritance
   - **Example**: `**/*.js` across 80% of directories → root `AGENTS.md`
   - **Rationale**: Widespread patterns require universal access

#### Real-World Coverage Scenarios

**Scenario 1: Perfect Localization**
```bash
Pattern: "docs/**/*.md"
Files: docs/README.md, docs/api/spec.md
Placement: docs/AGENTS.md
Coverage: ✅ Complete (all files inherit from docs/)
Efficiency: 🟢 High (~95% - docs agents see only doc rules)
```

**Scenario 2: Coverage-Driven Root Placement**
```bash
Pattern: "**/*.tsx" 
Files: src/components/Form.tsx, frontend/components/Header.tsx
Attempted: src/components/ + frontend/components/
Coverage: ❌ Gap (no common ancestor covers both)
Final Placement: ./AGENTS.md (root)
Efficiency: 🟡 Medium (~40% - some agents see irrelevant TSX rules)
Trade-off: Accepts pollution to guarantee coverage
```

**Scenario 3: Multi-Pattern Conflict**
```bash
Patterns: "**/*.py" (compliance), "**/*.tsx" (design), "src/**/*.py" (testing)
Result: Root gets compliance+design, src/ gets testing
Coverage: ✅ All files can access applicable instructions
Efficiency: 🟡 ~25% (some directories inherit unused patterns)
```

#### Compilation Process & Verbose Analysis

```bash
apm compile --verbose  # Shows complete optimization reasoning
```

**Phase 1: Pattern Analysis**
- File discovery with recursive pattern matching
- Directory-wise file counting and type analysis

**Phase 2: Mathematical Optimization**  
- Distribution scoring for each pattern
- Strategy selection (Single/Selective/Distributed)
- **Coverage Verification**: Check if proposed placements provide complete inheritance
- **Coverage Fallback**: Escalate to higher directories when gaps detected

**Phase 3: Performance Assessment**
- Context efficiency calculation per directory
- Pollution level assessment across project
- Mathematical foundation validation

#### Understanding Metrics: Coverage vs. Efficiency

**Context Efficiency = 12.1%** means:
- On average, agents see only 12.1% relevant instructions
- 87.9% of inherited context is irrelevant pollution
- **Assessment**: "Very poor" but may be **mathematically optimal** given coverage constraints

**Why Low Efficiency Can Be Correct**:
- Hierarchical coverage forces some instructions to root level
- Root placement creates pollution for specialized directories
- **Trade-off**: Guaranteed coverage at the cost of efficiency
- **Alternative**: Higher efficiency with coverage violations (data loss)

**Efficiency Benchmarks** (updated for coverage reality):
- **80-100%**: Excellent - perfect pattern locality
- **60-80%**: Good - well-optimized with minimal coverage conflicts  
- **40-60%**: Fair - moderate coverage-driven pollution
- **20-40%**: Poor - significant coverage constraints or pattern conflicts
- **0-20%**: Very Poor - major architectural issues or extensive cross-cutting patterns

#### Advanced Features

**Hierarchical Coverage Verification**: 
```python
def verify_coverage(placements, matching_files):
    """Ensure every matching file can inherit instruction through hierarchy"""
    covered_files = set()
    for placement in placements:
        covered_files.update(files_inheriting_from(placement))
    return matching_files.issubset(covered_files)
```

**Pattern Conflict Resolution**: When multiple strategies conflict, coverage takes priority over efficiency.

**Constitution Injection**: Project governance automatically injected at top of `AGENTS.md`
```
<!-- SPEC-KIT CONSTITUTION: BEGIN -->
hash: 34c5812dafc9 path: memory/constitution.md
[governance content]
<!-- SPEC-KIT CONSTITUTION: END -->
```

**Deterministic Optimization**: Cache clearing and sorted iteration ensure reproducible results.

**Universal Compatibility**: Generated `AGENTS.md` works with all major coding agents (GitHub Copilot, Cursor, Claude, etc.).

## Packaging & Distribution

**Manage like npm packages:**

```yaml
# apm.yml - Project configuration
name: my-ai-native-app
version: 1.0.0
scripts:
  impl-copilot: "copilot -p 'implement-feature.prompt.md'"
  review-copilot: "copilot -p 'code-review.prompt.md'" 
  docs-codex: "codex generate-docs.prompt.md -m github/gpt-4o-mini"
dependencies:
  mcp:
    - ghcr.io/github/github-mcp-server
```

**Share and reuse across projects:**
```bash
apm install                    # Install MCP dependencies
apm run impl-copilot --param feature="user-auth"
apm run review-copilot --param files="src/auth/"
```

## Overview

The APM CLI supports three types of primitives:

- **Chatmodes** (`.chatmode.md`) - Define AI assistant personalities and behaviors
- **Instructions** (`.instructions.md`) - Provide coding standards and guidelines for specific file types
- **Context** (`.context.md`, `.memory.md`) - Supply background information and project context

## File Structure

### Supported Locations

APM discovers primitives in these locations:

```
# APM-native structure
.apm/
├── chatmodes/           # AI assistant definitions
│   └── *.chatmode.md
├── instructions/        # Coding standards and guidelines  
│   └── *.instructions.md
├── context/            # Project context files
│   └── *.context.md
└── memory/             # Team info, contacts, etc.
    └── *.memory.md

# VSCode-compatible structure  
.github/
├── chatmodes/          # VSCode Copilot chatmodes
│   └── *.chatmode.md
└── instructions/       # VSCode Copilot instructions
    └── *.instructions.md

# Generic files (anywhere in project)
*.chatmode.md
*.instructions.md
*.context.md
*.memory.md
```

## Component Types Overview

Context implements the complete [AI-Native Development framework](https://danielmeppiel.github.io/awesome-ai-native/docs/concepts/) through four core component types:

### Instructions (.instructions.md)
**Context Engineering Layer** - Targeted guidance by file type and domain

Instructions provide coding standards, conventions, and guidelines that apply automatically based on file patterns. They implement strategic context loading that gives AI exactly the right information at the right time.

```yaml
---
description: Python coding standards and documentation requirements
applyTo: "**/*.py"
---
# Python Coding Standards
- Follow PEP 8 for formatting
- Use type hints for all function parameters
- Include comprehensive docstrings with examples
```

### Agent Workflows (.prompt.md)  
**Prompt Engineering Layer** - Executable AI workflows with parameters

Agent Workflows transform ad-hoc requests into structured, repeatable workflows. They support parameter injection, context loading, and validation gates for reliable results.

```yaml
---
description: Implement secure authentication system
mode: backend-dev
input: [auth_method, session_duration]
---
# Secure Authentication Implementation
Use ${input:auth_method} with ${input:session_duration} sessions
Review [security standards](../context/security.context.md) before implementation
```

### Chat Modes (.chatmode.md)
**Agent Specialization Layer** - AI assistant personalities with tool boundaries

Chat modes create specialized AI assistants focused on specific domains. They define expertise areas, communication styles, and available tools.

```yaml
---
description: Senior backend developer focused on API design
tools: ["terminal", "file-manager"]
expertise: ["security", "performance", "scalability"]
---
You are a senior backend engineer with 10+ years experience in API development.
Focus on security, performance, and maintainable architecture patterns.
```

### Context (.context.md)
**Knowledge Management Layer** - Optimized project information for AI consumption

Context files package project knowledge, architectural decisions, and team standards in formats optimized for LLM consumption and token efficiency.

```markdown
# Project Architecture
## Core Patterns
- Repository pattern for data access
- Clean architecture with domain separation
- Event-driven communication between services
```

## Primitive Types

### Chatmodes

Chatmodes define AI assistant personalities and specialized behaviors for different development tasks.

**Format:** `.chatmode.md`

**Frontmatter:**
- `description` (required) - Clear explanation of the chatmode purpose
- `applyTo` (optional) - Glob pattern for file targeting (e.g., `"**/*.{py,js}"`)
- `author` (optional) - Creator information
- `version` (optional) - Version string

**Example:**
```markdown
---
description: AI pair programming assistant for code review
author: Development Team
applyTo: "**/*.{py,js,ts}"
version: "1.0.0"
---

# Code Review Assistant

You are an expert software engineer specializing in code review.

## Your Role
- Analyze code for bugs, security issues, and performance problems
- Suggest improvements following best practices
- Ensure code follows team conventions

## Communication Style
- Be constructive and specific in feedback
- Explain reasoning behind suggestions
- Prioritize critical issues over style preferences
```

### Instructions

Instructions provide coding standards, conventions, and guidelines that apply to specific file types or patterns.

**Format:** `.instructions.md`

**Frontmatter:**
- `description` (required) - Clear explanation of the standards
- `applyTo` (required) - Glob pattern for file targeting (e.g., `"**/*.py"`)
- `author` (optional) - Creator information
- `version` (optional) - Version string

**Example:**
```markdown
---
description: Python coding standards and documentation requirements
applyTo: "**/*.py"
author: Development Team
version: "2.0.0"
---

# Python Coding Standards

## Style Guide
- Follow PEP 8 for formatting
- Maximum line length of 88 characters (Black formatting)
- Use type hints for all function parameters and returns

## Documentation Requirements
- All public functions must have docstrings
- Include Args, Returns, and Raises sections
- Provide usage examples for complex functions

## Example Format
```python
def calculate_metrics(data: List[Dict], threshold: float = 0.5) -> Dict[str, float]:
    """Calculate performance metrics from data.
    
    Args:
        data: List of data dictionaries containing metrics
        threshold: Minimum threshold for filtering
    
    Returns:
        Dictionary containing calculated metrics
    
    Raises:
        ValueError: If data is empty or invalid
    """
```

### Context Files

Context files provide background information, project details, and other relevant context that AI assistants should be aware of.

**Format:** `.context.md` or `.memory.md` files

**Frontmatter:**
- `description` (optional) - Brief description of the context
- `author` (optional) - Creator information
- `version` (optional) - Version string

**Examples:**

Project context (`.apm/context/project-info.context.md`):
```markdown
---
description: Project overview and architecture
---

# APM CLI Project

## Overview
Command-line tool for AI-powered development workflows.

## Key Technologies
- Python 3.9+ with Click framework
- YAML frontmatter for configuration
- Rich library for terminal output

## Architecture
- Modular runtime system
- Plugin-based workflow engine
- Extensible primitive system
```

Team information (`.apm/memory/team-contacts.memory.md`):
```markdown
# Team Contacts

## Development Team
- Lead Developer: Alice Johnson (alice@company.com)
- Backend Engineer: Bob Smith (bob@company.com)

## Emergency Contacts
- On-call: +1-555-0123
- Incidents: incidents@company.com

## Meeting Schedule
- Daily standup: 9:00 AM PST
- Sprint planning: Mondays 2:00 PM PST
```

## Discovery and Parsing

The APM CLI automatically discovers and parses all primitive files in your project:

```python
from apm_cli.primitives import discover_primitives

# Discover all primitives in current directory
collection = discover_primitives()

print(f"Found {collection.count()} primitives:")
print(f"  Chatmodes: {len(collection.chatmodes)}")
print(f"  Instructions: {len(collection.instructions)}")  
print(f"  Contexts: {len(collection.contexts)}")

# Access individual primitives
for chatmode in collection.chatmodes:
    print(f"Chatmode: {chatmode.name}")
    print(f"  Description: {chatmode.description}")
    if chatmode.apply_to:
        print(f"  Applies to: {chatmode.apply_to}")
```

## Validation

All primitives are automatically validated during discovery:

- **Chatmodes**: Must have description and content
- **Instructions**: Must have description, applyTo pattern, and content
- **Context**: Must have content (description optional)

Invalid files are skipped with warning messages, allowing valid primitives to continue loading.

## Best Practices

### 1. Clear Naming
Use descriptive names that indicate purpose:
- `code-review-assistant.chatmode.md`
- `python-documentation.instructions.md`
- `team-contacts.md`

### 2. Targeted Application
Use specific `applyTo` patterns for instructions:
- `"**/*.py"` for Python files
- `"**/*.{ts,tsx}"` for TypeScript React files
- `"**/test_*.py"` for Python test files

### 3. Version Control
Keep primitives in version control alongside your code. Use semantic versioning for breaking changes.

### 4. Organized Structure
Use the structured `.apm/` directories for better organization:
```
.apm/
├── chatmodes/
│   ├── code-reviewer.chatmode.md
│   └── documentation-writer.chatmode.md
├── instructions/
│   ├── python-style.instructions.md
│   └── typescript-conventions.instructions.md
└── context/
    ├── project-info.context.md
    └── architecture-overview.context.md
```

### 5. Team Collaboration
- Include author information in frontmatter
- Document the purpose and scope of each primitive
- Regular review and updates as standards evolve

## Integration with VSCode

For VSCode Copilot compatibility, place files in `.github/` directories:
```
.github/
├── chatmodes/
│   └── assistant.chatmode.md
└── instructions/
    └── coding-standards.instructions.md
```

These files follow the same format and will be discovered alongside APM-specific primitives.

## Error Handling

The primitive system handles errors gracefully:

- **Malformed YAML**: Files with invalid frontmatter are skipped with warnings
- **Missing required fields**: Validation errors are reported clearly
- **File access issues**: Permission and encoding problems are handled safely
- **Invalid patterns**: Glob pattern errors are caught and reported

This ensures that a single problematic file doesn't prevent other primitives from loading.

## Spec Kit Constitution Injection (Phase 0)

When present, a project-level constitution file at `memory/constitution.md` is injected at the very top of `AGENTS.md` during `apm compile`.

### Block Format
```
<!-- SPEC-KIT CONSTITUTION: BEGIN -->
hash: <sha256_12> path: memory/constitution.md
<entire original file content>
<!-- SPEC-KIT CONSTITUTION: END -->
```

### Behavior
- Enabled by default; disable via `--no-constitution` (existing block preserved)
- Idempotent: re-running compile without changes leaves file unchanged
- Drift aware: modifying `memory/constitution.md` regenerates block with new hash
- Safe: absence of constitution does not fail compilation (status MISSING in Rich table)

### Why This Matters
Ensures downstream AI tooling always has the authoritative governance / principles context without manual copy-paste. The hash enables simple drift detection or caching strategies later.