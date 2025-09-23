# GAWBLENZ


### COMMANDS:

**Create distribution object**
```
sui client call --function new --module distribution --package <PACKAGE_ID> --args <ADMIN_ADDRESS> <DISTRIBUTION_CAP_ID> --type-args <PACKAGE_ID>::gawblenz::Gawblen
```

**Update distribution phase**
```
sui client call --function update_phase --module distribution --package <PACKAGE_ID> --args <DISTRIBUTION_ID> <DISTRIBUTION_CAP_ID> <NEW_PHASE> --type-args <PACKAGE_ID>::gawblenz::Gawblen
```