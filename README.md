## Blend is a command line tool to manage projects with HappyFunJuice.

There's also a bot.

It integrates with

* HappyFunJuice
* github
* heroku
* hipchat
* lighthouse

# Installation

    gem 'blend'

# CLI Usage

    blend help
    blend projects
    blend project info Juice
    blend project addmember Juice will@happyfuncorp.com

# Using blend in other scripts

Blend::Client is the main entry point.  This will return a configured client, for example one of:

    Blend::Client::JuiceClient
    Blend::Client::HipchatClient
    Blend::Client::GithubClient

If you haven't logged in to juice, it will ask you, and then it will pull the auth code for the given project.  Sometimes it will return a organization API code since they work off of projects.  The hipchat is stored on the Organization level for example.

    require 'blend'
    juice = Blend::Client.juice_client
    juice.profile

or

    require 'blend'
    Blend::Client::hipchat_client.post_message room_name, message

## Details

This tool will be installed on developers and managers machine to facilitate the creation and management of third party services, and make it possible to wire them together.

# HappyFunJuice

The tool will require a juice account to use, and will piggy back on the authentication used in juice.  If it’s more expedient to call juice, rather than local gem call, do so.

# Project

There will be a concept of a project, and operations will be on services in the context of a project.

* (DONE) create project (juice create project)
* (DONE) list projects (juice list)

PROJECT:
* (DONE) open juice console url
* (TODO) open production url
* (TODO) open staging url
* (DONE) list who is on a project (juice actor api)
* (DONE) check and configure a project
** (DONE) Create a project if it doesn't exist
** (DONE) Create a hipchat room if it isn't set
** (DONE) Check to see if bugtracking is configured
** (DONE) Check to see if the github team is set
** (DONE) Check to see if github hooks are set
** (TODO) Add juice feeds for repos within the project

# GITHUB

## REPOS
* (DONE) list repos
* (DONE) create team
* (DONE) create repo
** (DONE) requires team
** (DONE) should follow naming, projectname, projectname-api, projectname-ios, projectname-android, etc.
* (DONE) create hipchat webhook

## TEAMS
* (DONE) list teams
* (DONE) add team to repo
* (DONE) list team members
* (DONE) add team member
* (DONE) remove team member

# HEROKU

* (TODO) create app <environment> - should be prod, stage, demo
* (DONE) list collaborators
* (TODO) add collaborator
* (TODO) remove collaborator
* (DONE) list addons
* (DONE) create HIPCHAT webhook
* (DONE) pull HEROKU config and set relevant webhooks

# AIRBRAKE
* (TODO) create HIPCHAT webhook

# HIPCHAT
* (DONE) create room
* (DONE) list room
* (DONE) post to room
* (DONE) list users

# LIGHTHOUSE
* (TODO) create project
* (TODO) add member
* (TODO) create HIPCHAT hook ?? possible
* (TODO) create GITHUB hook

## Development

The following environment variables will be used if set, otherwise they will be pulled from Juice

    JUICE_API_ENDPOINT || http://happyfuncorp.com/api
    HIPCHAT_API_TOKEN || juice_client.hipchat_api
    GITHUB_API_TOKEN || juice_client.auth( "github" )
    HEROKU_API_TOKEN || juice_client.auth( "heroku" )

## BOT

    cd litabot
    bundle
    lita

Commands for the bot are in blend/bot.rb.  Still needs work.