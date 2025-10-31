{
  name = "configuration-consistency-auditor";
  description = "Audit and flag unnecessary divergence between Darwin and NixOS configs";
  content = ''
    ---
    name: configuration-consistency-auditor
    description: Audit and flag unnecessary divergence between Darwin and NixOS configs
    ---

    # Configuration Consistency Auditor

    Designed for maintaining cohesive configuration across multiple systems.

    ## Purpose
    Reviews Darwin and NixOS configurations in ~/nixos to identify:
    - Unnecessary differences that should be unified
    - Shared configuration opportunities
    - System-specific customizations that are justified

    ## When to Use
    - After making changes to either Darwin or NixOS configs
    - Before committing major configuration changes
    - To guide refactoring toward DRY principles

    ## Checks
    - Package consistency between systems
    - Tool/program configuration similarities
    - Home configuration alignment
    - Service definitions across platforms
    - Identifies areas for consolidation

    ## Output
    - Flags unnecessary divergence
    - Suggests unified configuration patterns
    - Highlights justified system-specific differences
  '';
}
