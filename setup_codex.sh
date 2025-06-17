#!/usr/bin/env bash
# 1) Install Salesforce CLI
npm install -g sfdx-cli

# 2) (Optional) Add CLI plugins you need
sfdx plugins:install @salesforce/sfdx-lwc-jest

# 3) (Optional) Verify install
sfdx --version
