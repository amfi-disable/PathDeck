name: Feature request
description: Suggest an idea or enhancement for PathDeck
labels: ["enhancement"]
body:
  - type: textarea
    id: feature_description
    attributes:
      label: Describe the Enhancement
      description: A clear and concise description of what you want to happen.
      placeholder: Describe your idea here...
    validations:
      required: true
  - type: textarea
    id: rationale
    attributes:
      label: Rationale
      description: Why would this feature be useful to developer workflows?
    validations:
      required: true
