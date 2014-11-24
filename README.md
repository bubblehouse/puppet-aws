# bootstrap

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with bootstrap](#setup)
    * [What bootstrap affects](#what-bootstrap-affects)
    * [Setup requirements](#setup-requirements)

<!-- * [Beginning with bootstrap](#beginning-with-bootstrap)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development) -->

## Overview

Bootstrap utilities for EC2 and CloudFormation. A set of helper classes, functions
and facts to aid in creating userdata and cfn-init scripts.

## Module Description

There's a number of common actions that any boot script needs to do when booting
an EC2 instance on Amazon Web Services, and a myriad of ways to customize the
resulting instance.

This module seeks to standardize on Puppet and Ruby to reduce the complexity of
the CloudFormation templates and/or userdata scripts, while using the same
language/platform for initialization as provisioning and configuration.

### What bootstrap affects
## Setup

* Configures a wide number of different default settings for an instance
* Runs privileged AWS API commands via custom functions executed on the Puppetmaster

### Setup Requirements

Each instance that uses this package will need read access to various aspects
of the AWS environment.

Use of the custom functions require that the Puppetmaster is configured with
the appropriate level of access to create, attach, describe, etc.

It's assumed an instance profile will be configured on each machine, conversely
the AWS Ruby API provides for use of the usual environment variables.

<!-- ### Beginning with bootstrap

The very basic steps needed for a user to get the module up and running.

If your most recent release breaks compatibility or requires particular steps
for upgrading, you may wish to include an additional section here: Upgrading
(For an example, see http://forge.puppetlabs.com/puppetlabs/firewall).

## Usage

Put the classes, types, and resources for customizing, configuring, and doing
the fancy stuff with your module here.

## Reference

Here, list the classes, types, providers, facts, etc contained in your module.
This section should include all of the under-the-hood workings of your module so
people know what the module is touching on their system but don't need to mess
with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.

## Release Notes/Contributors/Etc **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You may also add any additional sections you feel are
necessary or important to include here. Please use the `## ` header. -->
