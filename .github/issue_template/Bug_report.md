name: Bug report
description: Create a report to help us improve PathDeck
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Thank you for reporting a bug! Please fill in as much detail as possible.
  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: A clear and concise description of what the bug is.
      placeholder: Describe the issue here...
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: Steps To Reproduce
      description: Steps to reproduce the behavior.
      placeholder: |
        1. Open PathDeck
        2. Click on ...
        3. See error
    validations:
      required: true
  - type: textarea
    id: system_info
    attributes:
      label: System Information
      description: Your macOS version, Shell details, etc.
      placeholder: |
        - macOS Version: macOS 14.5
        - Shell: zsh 5.9
        - PathDeck Version: V1.0.0
    validations:
      required: true
