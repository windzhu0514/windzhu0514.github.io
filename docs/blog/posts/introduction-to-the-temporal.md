---
# title: Temporal 分布式应用开发平台简介
description: 了解 Temporal 的核心概念与特性
date: 2025-04-23
categories: ['golang', '架构']
tags: ['Temporal', '分布式系统', '工作流', '微服务']
pin: false
draft: false
authors:
  - James Li
---

# Temporal 分布式应用开发平台简介

Temporal 是一个分布式应用开发平台，通过持久执行确保应用在故障时自动恢复，简化状态管理和错误处理。支持多语言SDK，提供工作流（Workflow）和活动（Activities）模型，内置可见性工具（UI/CLI）和事件历史记录。具备高可靠性、可扩展性，支持本地和云部署，适用于复杂业务流程。

Temporal 解决了开发者在构建分布式应用程序时面临的许多问题。但大多数问题都围绕以下这三个主题

<!-- more -->

## 可靠的分布式应用程序

Temporal 让开发者能够更轻松地构建和管理可靠且可扩展的应用程序，同时不影响生产效率。这个系统的设计确保了一旦应用程序的主要功能开始执行，无论需要几分钟、几小时、几天、几周，甚至几年，它都能执行到完成。Temporal 将这种特性称为持久执行。

在任何复杂系统中，故障都不可避免。软件工程师花费大量时间确保他们所构建的系统能够承受潜在的故障。Temporal 默认使您的代码执行可靠且持久。

通常，如果发生崩溃，应用程序的执行状态将丢失。应用程序无法记住故障前发生的情况，需要大量的错误处理逻辑和复杂的恢复代码才能继续。这一过程既耗时又容易出错，难以确保可靠性。

Temporal 跟踪应用程序的进度。如果发生意外情况，如断电，它确保应用程序可以从中断的地方继续运行——就像拥有终极自动保存功能一样（以 Activity 为重试单元）。将故障管理的责任从应用程序转移到平台，减少了对大量恢复编码、测试和维护任务的需求。

Temporal 是一个持久化执行平台。持久化执行通过确保应用程序能够运行至完成，来保证其在不利条件下仍能正确运行。这一转变简化了开发过程。如果发生故障或崩溃，您的业务流程仍能无缝运行，不受干扰。开发者将注意力集中在业务逻辑而非基础设施问题上，从而创建出天生具备可扩展性和可维护性的应用程序。

数千名开发者信赖 Temporal，将其用于订单处理、客户入职和支付处理等场景，因为它能帮助他们构建坚不可摧、具备弹性、持久且始终可用的应用程序。使用 Temporal，无论发生什么，您的应用程序都能持续运行。

## 高效开发范式与代码结构

通过将故障处理的负担从应用程序转移到平台，应用程序开发者需要编写、测试和维护的代码就减少了。Temporal 的编程模型为开发者提供了一种将业务逻辑表达为连贯工作流的方法，这比开发分布式代码库要容易得多。

选择与你偏好的编程语言最匹配的 SDK，就可以开始编写业务逻辑。在开发过程中，保持使用喜欢的IDE、库和工具。Temporal支持多语言和符合语言习惯的编程，这让开发者可以利用不同编程语言的优势，并将Temporal无缝集成到现有代码中。最棒的是，开发者无需管理队列或复杂的状态机来实现这一切。

## 可见的分布式应用状态

Temporal 提供了一整套开箱即用的工具，使开发者可以随时查看应用程序的状态。Temporal CLI（命令行界面）让开发者能够有效地管理、监控和调试Temporal 应用程序。基于浏览器的Web UI（用户界面）则让你能够快速定位、调试和解决生产环境中的问题。

Temporal 提供了一种构建可扩展且可靠应用程序的全新方式。

Temporal 提供了轻松的持久性，使应用程序能够在底层基础设施发生故障的情况下，持续运行数天、数周甚至数年而不会中断。这就是我们所说的持久执行。Temporal 也代表了软件开发中的范式转变。它不仅仅是让现有模式更加可靠；它更是为构建复杂的分布式系统开启了全新的方法。

Temporal 简化了状态管理，开发者无需编写大量额外代码来处理可能出现的各种问题。凭借内置的可扩展性，Temporal 确保您的应用程序无论规模大小或复杂程度如何，都能平稳运行。

## 概念

### Workflow（工作流）

从概念上讲，Workflow 是一系列步骤。您可能已经在日常生活中遇到过 Workflow，无论是：

*   使用移动应用程序转账
*   预订假期
*   提交费用报告
*   创建新员工入职流程
*   部署云基础设施
*   训练 AI 模型

Temporal Workflow 是您的业务逻辑，以代码形式定义，概述了流程中的每个步骤。

Temporal 不是一个无代码工作流引擎——它是代码即工作流。你无需在可视化界面中拖放步骤，而是可以用你喜欢的编程语言、代码编辑器和其他工具编写工作流代码。无代码引擎最终会遇到其局限性，而 Temporal 则让你对业务流程拥有完全的控制和灵活性，从而能够精确构建你所需的内容。

### Activities 活动

Activities 是 Workflow 中的独立工作单元。根据编程语言的不同，Activities 被定义为函数或方法。Activities 通常涉及与外部世界的交互，例如发送电子邮件、发起网络请求、写入数据库或调用 API，这些操作容易失败。您可以直接从 Workflow 代码中调用 Activities。

如果 Activity 失败，Temporal 会根据您的配置自动重试。由于 Activity 通常依赖于外部系统，可能会发生瞬态问题。这些问题包括网络故障、超时或服务中断等临时但关键的问题。您可以完全控制每个 Activity 的重试频率和次数。

### SDK（开发工具包）

开发者通过编写代码来创建 Temporal 应用程序，就像创建任何其他软件一样。

Temporal SDK（软件开发工具包）是一个开源库，开发者将其添加到应用程序中以使用 Temporal。它提供了在特定编程语言中构建工作流、活动以及各种其他 Temporal 功能所需的一切。

Temporal 提供六种 SDK：Java、Go、TypeScript、.NET、Python 和 PHP。由于 Temporal 支持多种编程语言，您可以在多语言团队中混合使用这些语言。您可以轻松地将任何 Temporal SDK 添加到当前项目中，而无需更改您已经用于构建和部署的工具。Temporal 完美融入您现有的技术栈。

### Temporal Service（Temporal 服务）

Temporal 有两个主要部分：

*   开发者编写的应用程序
*   Temporal Service（一组服务和组件）

Temporal 架构的核心是 Temporal Service，它为您的应用程序提供持久性、可扩展性和可靠性。您的应用程序与 Temporal Service 通信，Temporal Service 负责监督关键任务的执行，例如进行 API 调用，然后记录它们的完成情况。它维护每个事件的详细历史记录，并可靠地将其持久化到数据库中。

Temporal Service 的最大优势之一在于其处理故障的方式。Temporal Service 会详细记录您工作流中的每一步。通过保留工作流中每一步的历史记录，它确保即使出现问题，您的工作流也可以从最后一个成功点继续。Temporal Service 确切知道从哪里恢复，而不会丢失任何工作。这使您无需自己编写复杂的错误处理代码或繁琐的恢复机制。

您可以在自己的基础设施上运行 Temporal Service，或使用 Temporal Cloud，这是一种托管服务，可处理运维负担并提供可扩展性和专家支持。

### Workers（执行器）

Temporal 的真正能力源自开发者编写的应用程序与 Temporal 服务的结合。每当您的应用程序需要执行任务，如发送通知或处理支付时，Temporal 服务便会协调所需完成的工作。由 Temporal SDK 提供并作为您应用程序一部分的 Workers，随后执行在您的工作流中定义的任务。

Worker 轮询 Temporal Service 以查看是否有可用任务，Temporal Service 将任务与 Worker 匹配。Worker 根据任务中指定的详细信息运行 Workflow 代码。

此次合作对于构建可靠、可扩展且持久的应用程序至关重要。您可以运行多个 Workers——通常是几十个、几百个，甚至几千个——以提升应用程序的性能和可扩展性。

一个常见的误解是 Temporal Service 运行你的代码。实际上，Worker 运行你的代码并直接处理你的数据。Temporal 应用程序在设计上是安全的。工作流和活动无缝部署在你的基础设施内，完全集成到你的应用程序中。你的数据也通过你的加密库和密钥得到保护。你从头到尾都完全掌控着应用程序的安全性。

### Visibility 可见性

Temporal 提供了两种工具，让您能够深入了解幕后情况并与您的工作流进行交互。这些工具在调试方面非常强大，并能为您的应用程序提供实时监控。

#### Temporal UI

Temporal UI 是一个基于浏览器的用户界面，允许您查看应用程序的进度。它也被称为 Web UI，还可以帮助您快速隔离、调试和解决生产问题。
工作流页面

![](https://docs.temporal.io/img/webui/workflow-details-page-hiw.avif)

#### Temporal CLI

Temporal CLI 是一个命令行界面工具，用于管理、监控和调试 Temporal 应用程序。通过终端，您可以：

*   启动工作流
*   跟踪工作流程的进度
*   取消或终止工作流
*   并执行其他操作

Temporal CLI 为开发者提供了直接访问 Temporal 服务的功能，便于本地开发使用。

### Event History（事件历史）

借助 Temporal，您的工作流可以从崩溃中无缝恢复。这得益于事件历史记录，它完整且持久地记录了工作流执行生命周期中发生的一切，以及 Temporal 服务在重放期间持久保存事件的能力。

Temporal 使用事件历史记录来记录过程中的每一步。每当您的工作流定义通过 API 调用执行活动或启动计时器时，它并不会直接执行该操作，而是向 Temporal 服务发送一个命令。

Command 是 Worker 在 Workflow Task Execution 完成后向 Temporal Service 发出的请求操作。Temporal Service 将根据这些 Command 执行操作，例如调度 Activity 或设置计时器。这些 Command 随后被映射为 Event，并在发生故障时持久化。例如，如果 Worker 崩溃，Worker 会使用 Event History 重放代码并重新创建 Workflow Execution 的状态，使其恢复到崩溃前的状态。然后，它会从故障点继续执行，就像故障从未发生过一样。

## 特性

通过 Temporal SDK，Temporal 提供了广泛的功能，使开发者能够构建适用于各种用例的应用程序。

*   **核心应用原语：** 使用 Workflows、Activities 和 Workers 开发和运行您的应用程序。
*   **测试套件：** 每个 Temporal SDK 都附带一个测试套件，使开发者能够像测试其他应用程序一样测试他们的应用。
*   **可调度工作流：** 在特定时间或按指定的时间间隔启动业务流程。
*   **可中断工作流：** 取消或终止已在进行中的业务流程（Workflow），并对已执行的步骤进行补偿。
*   **运行时保障措施：** 防止在运行时执行可避免的错误和问题。
*   **故障检测与缓解：** 通过超时机制检测故障，并配置自动重试以缓解问题。
*   **Temporal Nexus：** 连接跨（及内部）隔离命名空间的 Temporal 应用程序，以提升模块化、安全性、调试和故障隔离能力。Nexus 支持跨团队、跨领域和多区域的使用场景。
*   **工作流消息传递：** 构建响应式应用程序，在运行时对事件作出反应，并从正在进行的工作流中实现数据检索。
*   **版本控制：** 支持为长时间运行的业务流程提供多个版本的业务逻辑。
*   **可观测性：** 列出业务流程，查看其状态，并设置包含指标的仪表板。
*   **调试：** 发现表面错误并逐步检查代码以找到问题。
*   **数据加密：** 转换数据并保护应用程序用户的隐私。
*   **吞吐量可组合性：** 按数据流、团队所有权或其他组织因素拆分业务流程。
*   **云自动化：** 通过 Temporal 的云自动化简化云管理并提升安全性。
*   **低延迟：** 让您的应用程序更快、性能更强、效率更高。
*   **多租户：** 提高效率和成本效益。

## 部署

Temporal 提供了收费的在线托管，也支持部署本地开发环境和 Docker 方式的私有部署。Temporal 有多种私有部署方式，根据使用场景和部署位置来选不同的部署方式。

以 Docker Compose 方式部署举例：

1.  克隆 [temporalio/docker-compose](https://github.com/temporalio/docker-compose) 仓库
2.  在仓库根目录运行 `docker compose up` 命令，后台运行请添加 `-d` 参数

```bash
git clone https://github.com/temporalio/docker-compose.git
cd docker-compose
docker compose up # -d
```

## 故障排除

### missing csrf token in request header

创建调度器的时页面上显示 `missing csrf token in request header`，原因是：

*   temporal 托管地址不是 localhost
*   UI 后台通过HTTP访问，而不是HTTPS
*   启用了安全Cookie

在 docker-compose.yml 里添加 `TEMPORAL_CSRF_COOKIE_INSECURE=true` 配置项。

```yaml
temporal-ui:
    container_name: temporal-ui
    depends_on:
      - temporal
    environment:
      - TEMPORAL_ADDRESS=temporal:7233
      - TEMPORAL_CORS_ORIGINS=http://localhost:3000
      - TEMPORAL_CSRF_COOKIE_INSECURE=true # 启用安全Cookie
```

## 参考资料

*   [Why Temporal? | Temporal Platform Documentation](https://docs.temporal.io/evaluate/why-temporal)

*   [Deploying a Temporal Service | Temporal Platform Documentation](https://docs.temporal.io/self-hosted-guide/deployment)

*   [Missing CSRF token · Issue #793 · temporalio/ui](https://github.com/temporalio/ui/issues/793)
