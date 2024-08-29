---
title: Supafana—Motivation and Implementation
description: Why and how we built Supafana, an observability solution for Supabase that wraps the Grafana and Prometheus Docker recipe from Supabase
publishDate: "August 28, 2024"
authors:
  - supafana
thumbnailImage: "./assets/supafana-why-and-how/thumb.png"
coverImage: "./assets/supafana-why-and-how/cover.png"
socialImage: "./assets/supafana-why-and-how/social.png"
coverImageAspectRatio: "14:4"
---

## Introduction

[Supabase](https://supabase.com) is a really, really powerful "no backend backend" solution, offering a relational database, authentication, edge functions, storage, and many other thoughtfully-designed subsystems. It _actually_ enables developers to focus on building their applications without worrying about the complexities of managing backend infrastructure.

However, one area where Supabase currently falls short is in providing a sophisticated observability solution out of the box. To address this gap, the Supabase team has created a [Docker setup](https://github.com/supabase/supabase-grafana) that allows users to quickly spin up a [Grafana](https://grafana.com/) and [Prometheus](https://prometheus.io/)-powered database dashboard.

While this setup is a great starting point, we recognized that securely deploying and maintaining such containers for long-term use by an organization requires a skill set that many Supabase users may not have. That's why we developed Supafana—a service designed to simplify the deployment of supabase-grafana Docker containers, making database observability more accessible to the broader Supabase community, and some revenue for us.

## Motivation

In short, we set out to build a web-based tool that enables a Supabase user to deploy a [Grafana/Prometheus observability dashboard](https://github.com/supabase/grafana-dashboards) with a handful of clicks.

Additionally, we wanted the dashboard a) to be behind HTTPS and b) to retain its data after Grafana host/container restart.

### Integrating with Supabase

While looking for the best way to integrate with Supabase, we discovered a [recently-published article](https://supabase.com/docs/guides/platform/oauth-apps/build-a-supabase-integration) describing how to "build a Supabase integration", enabling a vendor (e.g., Supafana) to publish a application with certain permission scopes and an administrator of a Supabase organization to install it via OAuth2 workflow.

Once the OAuth2 handshake succeeds, the vendor's application backend can make calls to the [Supabase Management API](https://supabase.com/docs/reference/api/introduction) on behalf of the Supabase organization where the application is installed.

### The nitty-gritty

In our case, our product challenge was to display a list of Supabase projects belonging to a user/organization, each accompanied by a "Provision Grafana" button. A click on this button would trigger the creation of some sort of a Grafana/Prometheus "host" (either container, VM, or both—we explain our choice further), parameterized with the Supabase project ref and its service key.

Interesingly, the Supabase integration OAuth2 handshake does not identify the user performing the flow to the third party (e.g., Supafana). We ran into two situations where this poses a problem: managing notification preferences and—related—identifying the user in customer support interactions. To solve this problem, we used the Supabase Management API to retrieve the list of _all_ users belonging to a given Supabase organization and built a simple "verify your email" flow, enabling the user to self-identify.

### B-side goals

Some of our B-side goals included learning Microsoft Azure infrastructure development, finding a way to onboard developers in an efficient and SOC 2-compliant manner (i.e. while protecting production assets), and minimizing third-party dependencies.

To the last point, we reluctantly opted against using Supabase for Supafana not because it would constitute an external dependency, but to avoid a scenario where Supabase is having issues, but users can't get to their observability dashboards because Supabase is having issues. However, as it stands, without a backup authentication strategy, Supafana is still fairly coupled to Supabase due to the OAuth2 flow. To de-risk this, we plan on re-using the key bits of the email verification approach described in **The nitty-gritty** section to facilitate backup authentication.

The only external services we're currently using are Stripe for subscription management and [Loops](https://loops.so) for transactional email.

### The cyberpunk technomedley

Before diving into the Supafana infrastructure, let's take a cursory look at some of the key technologies we've used.

Note that Supafana is fully open-source under the MIT license, available at https://github.com/fogbender/supafana for your gentle perusal and aggressive starring.

- We make heavy use of [Nix](https://nixos.org/) (with flakes) for development environments, builds, and core package management
- Piggy-backing on the above, we run NixOS on Azure virtual machines
- Because we use Nix flakes, we use https://github.com/serokell/deploy-rs to manage deployments
- The [Astro metaframework](https://astro.build) is used to assemble a combination of static (landing page, blog) and dynamic (React) content
- [TanStack Query](https://tanstack.com/query/latest) and a little bit of [Jotai](https://jotai.org/) is used for React state management
- OTP/BEAM (Elixir) runs our application server
- Postgres is our database

## Infrastructure overview

Note that Supafana is in its early MVP phase—some infrastructure decisions are expected to be non-optimal.

Supafana is designed to run on [Microsoft Azure](https://azure.microsoft.com/en-us/)—it's kind of like AWS, except not at all.

Currently, there are two main environments ([test](https://supafana-test.com) and [prod](https://supafana.com)) and several environments for developers. During deployment, each environment creates a public DNS record.

All the resources from an environment `env` are contained in an [Azure resource group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal) named `supafana-${env}-rg`.

There is also a common resource group called `supafana-common-rg`—it contains all the resources shared between environments, such as images, templates, and DNS configurations.

Whenever possible, the `supafana-${env}-${resource}` scheme is used to name resources.

The entire infrastructure is described by the [Azure Bicep language](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) and deployed via the [Azure Command-Line Interface (CLI)](https://learn.microsoft.com/en-us/cli/azure/) tool.

### Core structure

`supafana-common-rg`

- [Azure Compute Gallery](https://learn.microsoft.com/en-us/azure/virtual-machines/azure-compute-gallery) `supafanasig`: versioned virtual machine images named **grafana** and **supafana**
- [Azure Container Registry](https://azure.microsoft.com/en-us/products/container-registry) `supafanacr`: versioned [supabase-grafana](https://github.com/supabase/supabase-grafana) Docker images
- Template spec `grafana-template`: a versioned [ARM](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview) template for deploying **grafana** VMs
- Public DNS configuration for supafana.com
- Public DNS configuration for supafana-test.com

`supafana-${env}-rg`

- [Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) `supafana-${env}-vnet` with several subnets:

  - `supafana-${env}-api-subnet` - subnet for the application server/gateway VM

  - `supafana-${env}-grafana-subnet` - subnet for **grafana** dynamic VMs, does not have access to other subnets and VMs

  - `supafana-${env}-db-subnet` - subnet delegated for DB usage

- [Key Vault](https://azure.microsoft.com/en-us/products/key-vault) `supafana-${env}-vault` - secret keys for encrypting environment secrets

- Private DNS Zone `supafana-${env}.local`

- [Azure Database for PostgreSQL - Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/)

  - Has no public IP access
  - Deployed within the `supafana-${env}-db` subnet
  - Uses a [private DNS](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview) zone

- Azure Static Web App

  - No public IP
  - Uses a [private endpoint](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview) to the private `supafana-${env}-api` subnet
  - Uses a private DNS zone

- N [Virtual Machines](https://azure.microsoft.com/en-us/products/virtual-machines) `supafana-${env}-grafana-${project_id}` (Grafana servers) created dynamically

  - Runs a [Podman](https://podman.io/) container with:

    - Prometheus connected to a customer's Supabase instance
    - Grafana with the Supabase dashboard template

  - Note that we opted for VMs instead of [containers](https://azure.microsoft.com/en-us/products/category/containers) because, unlike containers, VMs are guaranteed to keep the same IP address after restart

- Azure Virtual Machine `supafana-${env}-api` - the backend server
  - Elixir backend application
  - nginx gateway that terminates SSL traffic and routes requests to the server, static web application, and Grafana instances
