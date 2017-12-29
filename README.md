# Observium Agent Installer

Install Observium agent using a single script

## Requirements

- Ubuntu Server 16.04
- [Observium Professional](http://www.observium.org/subscribe/)

## Installation

1. `git clone https://github.com/zeropingheroes/observium-agent-installer.git && cd observium-agent-installer`

## Configuration

All configuration is done via environment variables:

1. Copy `.env.example` to `.env`
2. Edit `.env` and add the desired values for your installation

Alternatively set the environment variables manually by running:

`export VARIABLE=value`

## Usage

`sudo ./observium-agent-installer.sh`
