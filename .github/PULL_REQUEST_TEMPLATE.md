## Description

Provide a brief description of the changes in this PR.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Configuration change

## Related Issues

Closes #(issue number)

## Changes Made

Provide a detailed list of changes:

- Change 1
- Change 2
- Change 3

## Testing

Describe the tests you ran to verify your changes:

- [ ] Terraform fmt
- [ ] Terraform validate
- [ ] Terraform plan reviewed
- [ ] Terraform apply in dev environment
- [ ] Manual testing performed
- [ ] Security scan passed (tfsec/checkov)
- [ ] Cost impact analyzed

### Test Configuration

**Environment**: dev/prod
**Region**: us-west-2
**Terraform Version**: 1.6.0

## Impact

### Resources Affected

List the resources that will be created, modified, or destroyed:

- aws_ecs_cluster.main (modified)
- aws_alb.main (no change)
- etc.

### Cost Impact

- [ ] No cost impact
- [ ] Cost increase (provide estimate)
- [ ] Cost decrease (provide estimate)
- [ ] Cost neutral

### Breaking Changes

If this is a breaking change, describe:
- What breaks
- Migration path
- Backward compatibility considerations

## Security Considerations

- [ ] No security implications
- [ ] Security review completed
- [ ] New IAM permissions required (list below)
- [ ] Secrets/credentials handled properly
- [ ] Network changes reviewed

### Security Checklist

- [ ] Least privilege IAM policies
- [ ] No hardcoded secrets
- [ ] Security group rules reviewed
- [ ] Encryption enabled where needed

## Documentation

- [ ] README updated
- [ ] CHANGELOG updated
- [ ] Module documentation updated
- [ ] Architecture diagrams updated (if applicable)
- [ ] Comments added to complex code

## Screenshots / Outputs

If applicable, add screenshots or terraform plan outputs:

```
# Paste terraform plan output here (sanitize sensitive data)
```

## Deployment Notes

Special instructions for deploying this change:

- Step 1
- Step 2
- Rollback procedure if needed

## Checklist

Before submitting this PR, please check:

- [ ] Code follows the project's coding standards
- [ ] All pre-commit hooks pass
- [ ] Terraform fmt applied
- [ ] Terraform validate passes
- [ ] Security scans completed (tfsec, checkov)
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Commit messages follow conventional commits
- [ ] All tests pass
- [ ] I have reviewed my own code
- [ ] I have commented complex code sections
- [ ] No TODO or FIXME comments left

## Reviewer Notes

Anything specific you want reviewers to focus on:

---

## For Maintainers

- [ ] Code review completed
- [ ] Tests verified
- [ ] Documentation reviewed
- [ ] Cost impact acceptable
- [ ] Security review completed
- [ ] Ready to merge
