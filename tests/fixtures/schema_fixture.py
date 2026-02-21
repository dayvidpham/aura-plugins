"""Combinatorial schema mutation fixture for validate_schema.py tests.

Defines mutations organized by validation layer (structural, referential, semantic).
Each mutation transforms a valid schema into one with a specific detectable error.
The SchemaFixture class loads the baseline XML and applies mutations to fresh copies.
"""

from __future__ import annotations

import copy
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterator

from validate_schema import ErrorLayer


# ─── Mutation dataclass ──────────────────────────────────────────────────────


@dataclass(frozen=True)
class SchemaMutation:
    """A single schema mutation that should produce a detectable validation error."""

    name: str
    layer: ErrorLayer
    description: str
    expected_fragment: str  # substring expected in error message
    category: str  # grouping (e.g., "phase", "label", "handoff")
    apply_fn: Callable[[ET.Element], None]  # mutates root in-place


# ─── Mutation factories ──────────────────────────────────────────────────────


def _del_attr(xpath: str, attr: str) -> Callable[[ET.Element], None]:
    """Factory: delete an attribute from an element found by xpath."""

    def apply(root: ET.Element) -> None:
        elem = root.find(xpath)
        if elem is not None and attr in elem.attrib:
            del elem.attrib[attr]

    return apply


def _set_attr(xpath: str, attr: str, value: str) -> Callable[[ET.Element], None]:
    """Factory: set an attribute value on an element found by xpath."""

    def apply(root: ET.Element) -> None:
        elem = root.find(xpath)
        if elem is not None:
            elem.set(attr, value)

    return apply


def _add_elem(
    parent_xpath: str, tag: str, attribs: dict[str, str]
) -> Callable[[ET.Element], None]:
    """Factory: add a child element to the parent found by xpath."""

    def apply(root: ET.Element) -> None:
        parent = root.find(parent_xpath)
        if parent is not None:
            el = ET.SubElement(parent, tag)
            for k, v in attribs.items():
                el.set(k, v)

    return apply


def _remove_child(xpath: str, child_tag: str) -> Callable[[ET.Element], None]:
    """Factory: remove a direct child element by tag from element found by xpath."""

    def apply(root: ET.Element) -> None:
        parent = root.find(xpath)
        if parent is not None:
            child = parent.find(child_tag)
            if child is not None:
                parent.remove(child)

    return apply


# ─── Structural mutations ────────────────────────────────────────────────────

STRUCTURAL_MUTATIONS: list[SchemaMutation] = [
    SchemaMutation(
        name="missing_phase_domain",
        layer=ErrorLayer.STRUCTURAL,
        description="Phase without domain attribute",
        expected_fragment="domain",
        category="phase",
        apply_fn=_del_attr(".//phase[@id='p1']", "domain"),
    ),
    SchemaMutation(
        name="missing_phase_number",
        layer=ErrorLayer.STRUCTURAL,
        description="Phase without number attribute",
        expected_fragment="number",
        category="phase",
        apply_fn=_del_attr(".//phase[@id='p1']", "number"),
    ),
    SchemaMutation(
        name="missing_substep_label_ref",
        layer=ErrorLayer.STRUCTURAL,
        description="Substep without label-ref attribute",
        expected_fragment="label-ref",
        category="substep",
        apply_fn=_del_attr(".//substep[@id='s1']", "label-ref"),
    ),
    SchemaMutation(
        name="missing_substep_order",
        layer=ErrorLayer.STRUCTURAL,
        description="Substep without order attribute",
        expected_fragment="order",
        category="substep",
        apply_fn=_del_attr(".//substep[@id='s1']", "order"),
    ),
    SchemaMutation(
        name="missing_label_value",
        layer=ErrorLayer.STRUCTURAL,
        description="Label without value attribute",
        expected_fragment="value",
        category="label",
        apply_fn=_del_attr(".//label[@id='L-p1s1']", "value"),
    ),
    SchemaMutation(
        name="missing_label_phase_ref",
        layer=ErrorLayer.STRUCTURAL,
        description="Non-special label without phase-ref",
        expected_fragment="phase-ref",
        category="label",
        apply_fn=_del_attr(".//label[@id='L-p1s1']", "phase-ref"),
    ),
    SchemaMutation(
        name="missing_constraint_should_not",
        layer=ErrorLayer.STRUCTURAL,
        description="Constraint without should-not attribute",
        expected_fragment="should-not",
        category="constraint",
        apply_fn=_del_attr(".//constraint[@id='C-test']", "should-not"),
    ),
    SchemaMutation(
        name="missing_handoff_content_level",
        layer=ErrorLayer.STRUCTURAL,
        description="Handoff without content-level attribute",
        expected_fragment="content-level",
        category="handoff",
        apply_fn=_del_attr(".//handoff[@id='h-test']", "content-level"),
    ),
    SchemaMutation(
        name="missing_title_convention_created_by",
        layer=ErrorLayer.STRUCTURAL,
        description="Title convention without created-by",
        expected_fragment="created-by",
        category="title-convention",
        apply_fn=_del_attr(".//title-convention", "created-by"),
    ),
    SchemaMutation(
        name="missing_document_path",
        layer=ErrorLayer.STRUCTURAL,
        description="Document without path attribute",
        expected_fragment="path",
        category="document",
        apply_fn=_del_attr(".//document[@id='doc-test']", "path"),
    ),
    SchemaMutation(
        name="missing_axis_letter",
        layer=ErrorLayer.STRUCTURAL,
        description="Axis without letter attribute",
        expected_fragment="letter",
        category="axis",
        apply_fn=_del_attr(".//axis[@id='axis-A']", "letter"),
    ),
    SchemaMutation(
        name="missing_command_name",
        layer=ErrorLayer.STRUCTURAL,
        description="Command without name attribute",
        expected_fragment="name",
        category="command",
        apply_fn=_del_attr(".//command[@id='cmd-test']", "name"),
    ),
]

# ─── Referential integrity mutations ─────────────────────────────────────────

REFERENTIAL_MUTATIONS: list[SchemaMutation] = [
    SchemaMutation(
        name="dangling_label_phase_ref",
        layer=ErrorLayer.REFERENTIAL,
        description="Label references nonexistent phase",
        expected_fragment="p99",
        category="label_to_phase",
        apply_fn=_set_attr(".//label[@id='L-p1s1']", "phase-ref", "p99"),
    ),
    SchemaMutation(
        name="dangling_label_substep_ref",
        layer=ErrorLayer.REFERENTIAL,
        description="Label references nonexistent substep",
        expected_fragment="s99",
        category="label_to_substep",
        apply_fn=_set_attr(".//label[@id='L-p1s1']", "substep-ref", "s99"),
    ),
    SchemaMutation(
        name="dangling_substep_label_ref",
        layer=ErrorLayer.REFERENTIAL,
        description="Substep references nonexistent label",
        expected_fragment="L-nonexistent",
        category="substep_to_label",
        apply_fn=_set_attr(".//substep[@id='s1']", "label-ref", "L-nonexistent"),
    ),
    SchemaMutation(
        name="dangling_command_role_ref",
        layer=ErrorLayer.REFERENTIAL,
        description="Command references nonexistent role",
        expected_fragment="bad-role",
        category="command_to_role",
        apply_fn=_set_attr(".//command[@id='cmd-test']", "role-ref", "bad-role"),
    ),
    SchemaMutation(
        name="dangling_handoff_at_phase",
        layer=ErrorLayer.REFERENTIAL,
        description="Handoff references nonexistent phase",
        expected_fragment="p99",
        category="handoff_to_phase",
        apply_fn=_set_attr(".//handoff[@id='h-test']", "at-phase", "p99"),
    ),
    SchemaMutation(
        name="dangling_handoff_source_role",
        layer=ErrorLayer.REFERENTIAL,
        description="Handoff references nonexistent source role",
        expected_fragment="bad-role",
        category="handoff_to_role",
        apply_fn=_set_attr(".//handoff[@id='h-test']", "source-role", "bad-role"),
    ),
    SchemaMutation(
        name="dangling_transition_to_phase",
        layer=ErrorLayer.REFERENTIAL,
        description="Transition references nonexistent phase",
        expected_fragment="p99",
        category="transition_to_phase",
        apply_fn=_set_attr(".//transition[@to-phase='p2']", "to-phase", "p99"),
    ),
    SchemaMutation(
        name="dangling_title_label_ref",
        layer=ErrorLayer.REFERENTIAL,
        description="Title convention references nonexistent label",
        expected_fragment="L-nonexistent",
        category="title_to_label",
        apply_fn=_set_attr(".//title-convention", "label-ref", "L-nonexistent"),
    ),
    SchemaMutation(
        name="dangling_title_phase_ref",
        layer=ErrorLayer.REFERENTIAL,
        description="Title convention references nonexistent phase",
        expected_fragment="p99",
        category="title_to_phase",
        apply_fn=_set_attr(".//title-convention", "phase-ref", "p99"),
    ),
    SchemaMutation(
        name="dangling_entity_refs",
        layer=ErrorLayer.REFERENTIAL,
        description="Document entity references nonexistent phase",
        expected_fragment="p99",
        category="entity_to_phase",
        apply_fn=_set_attr(".//entity[@type='phase']", "refs", "p1,p99"),
    ),
    SchemaMutation(
        name="dangling_phase_ref_child",
        layer=ErrorLayer.REFERENTIAL,
        description="Phase-ref child element references nonexistent phase",
        expected_fragment="p99",
        category="phase_ref_child",
        apply_fn=_set_attr(
            ".//role[@id='role-test']/owns-phases/phase-ref[@ref='p1']", "ref", "p99"
        ),
    ),
]

# ─── Semantic mutations ──────────────────────────────────────────────────────

SEMANTIC_MUTATIONS: list[SchemaMutation] = [
    SchemaMutation(
        name="phase_numbers_gap",
        layer=ErrorLayer.SEMANTIC,
        description="Phase numbers have a gap (1, 5 instead of 1, 2)",
        expected_fragment="sequential",
        category="phase_numbering",
        apply_fn=_set_attr(".//phase[@id='p2']", "number", "5"),
    ),
    SchemaMutation(
        name="phase_wrong_domain",
        layer=ErrorLayer.SEMANTIC,
        description="Phase 1 has wrong domain (should be user)",
        expected_fragment="should be",
        category="domain_consistency",
        apply_fn=_set_attr(".//phase[@id='p1']", "domain", "impl"),
    ),
    SchemaMutation(
        name="phase_no_substeps",
        layer=ErrorLayer.SEMANTIC,
        description="Phase with no substeps",
        expected_fragment="no substeps",
        category="substep_coverage",
        apply_fn=_remove_child(".//phase[@id='p2']", "substeps"),
    ),
    SchemaMutation(
        name="parallel_no_group",
        layer=ErrorLayer.SEMANTIC,
        description="Parallel substep without parallel-group attribute",
        expected_fragment="parallel-group",
        category="parallel_grouping",
        apply_fn=_set_attr(".//substep[@id='s1']", "execution", "parallel"),
    ),
    SchemaMutation(
        name="duplicate_label_value",
        layer=ErrorLayer.SEMANTIC,
        description="Two labels with the same value",
        expected_fragment="duplicate value",
        category="label_uniqueness",
        apply_fn=_add_elem(
            ".//labels",
            "label",
            {
                "id": "L-dup",
                "value": "aura:p1-user:s1-test",  # same as L-p1s1
                "special": "true",
            },
        ),
    ),
    SchemaMutation(
        name="role_no_phases",
        layer=ErrorLayer.SEMANTIC,
        description="Role that owns no phases",
        expected_fragment="no phases",
        category="role_coverage",
        apply_fn=_remove_child(".//role[@id='role-test']", "owns-phases"),
    ),
    SchemaMutation(
        name="command_phases_no_file",
        layer=ErrorLayer.SEMANTIC,
        description="Command has phases but no file child",
        expected_fragment="no <file>",
        category="command_completeness",
        apply_fn=_remove_child(".//command[@id='cmd-test']", "file"),
    ),
    SchemaMutation(
        name="duplicate_axis_letter",
        layer=ErrorLayer.SEMANTIC,
        description="Two axes with the same letter",
        expected_fragment="duplicate letter",
        category="axis_uniqueness",
        apply_fn=_add_elem(
            ".//review-axes",
            "axis",
            {"id": "axis-dup", "letter": "A", "name": "Duplicate"},
        ),
    ),
    SchemaMutation(
        name="domain_not_in_enum",
        layer=ErrorLayer.SEMANTIC,
        description="Phase domain not in DomainType enum",
        expected_fragment="DomainType",
        category="domain_enum",
        apply_fn=_set_attr(".//phase[@id='p1']", "domain", "unknown"),
    ),
]

ALL_MUTATIONS = STRUCTURAL_MUTATIONS + REFERENTIAL_MUTATIONS + SEMANTIC_MUTATIONS


# ─── Fixture class ───────────────────────────────────────────────────────────


class SchemaFixture:
    """Load and apply combinatorial mutations to a baseline valid schema."""

    def __init__(self, fixture_path: str | Path | None = None):
        if fixture_path is None:
            fixture_path = Path(__file__).parent / "schema_valid_minimal.xml"
        self.fixture_path = Path(fixture_path)
        self._tree = ET.parse(str(self.fixture_path))

    def fresh_root(self) -> ET.Element:
        """Return a deep copy of the fixture's root element."""
        return copy.deepcopy(self._tree.getroot())

    def apply_mutation(self, mutation: SchemaMutation) -> ET.Element:
        """Apply a mutation to a fresh copy and return the mutated root."""
        root = self.fresh_root()
        mutation.apply_fn(root)
        return root

    def generate_structural_mutations(self) -> Iterator[SchemaMutation]:
        yield from STRUCTURAL_MUTATIONS

    def generate_referential_mutations(self) -> Iterator[SchemaMutation]:
        yield from REFERENTIAL_MUTATIONS

    def generate_semantic_mutations(self) -> Iterator[SchemaMutation]:
        yield from SEMANTIC_MUTATIONS

    def generate_all_mutations(self) -> Iterator[SchemaMutation]:
        yield from self.generate_structural_mutations()
        yield from self.generate_referential_mutations()
        yield from self.generate_semantic_mutations()
