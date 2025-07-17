
- [事前準備](#事前準備)
  - [GitHub リポジトリの準備](#github-リポジトリの準備)
  - [AWS のアクセスキー設定](#aws-のアクセスキー設定)
  - [HCP Terraform のアカウント開設](#hcp-terraform-のアカウント開設)
- [Terraform ハンズオン](#terraform-ハンズオン)
  - [ゴール目標](#ゴール目標)
  - [HCP TerraformのWorkspaceを作成する](#hcp-terraformのworkspaceを作成する)
  - [最小リソースの作成](#最小リソースの作成)
  - [VPC を作成する](#vpc-を作成する)
  - [EC2 を追加する](#ec2-を追加する)
  - [ALB を追加する](#alb-を追加する)
  - [開発環境、本番環境をそれぞれ作る](#開発環境本番環境をそれぞれ作る)
  - [(発展編) Policy as Codeでガードレールを実装する](#発展編-policy-as-codeでガードレールを実装する)
- [片付け](#片付け)
  - [作成したリソースの削除](#作成したリソースの削除)

## 事前準備

### GitHub リポジトリの準備
GitHubにハンズオン用のリポジトリ`[MMDD]-hcp-terraform-handson`を作成します。
リポジトリを作成したら、新規の作業ディレクトリに移動し、皆様の作業端末から`main.tf`を追加してpushします。

```bash
echo "# main.tf" > main.tf
git init
git add main.tf
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:[USER]/[MMDD]-hcp-terraform-handson.git
git push -u origin main
```

### AWS のアクセスキー設定

次に、Terraform を通じて AWS を操作するためのアクセスキーを発行します。
本設定は**AWS様よりからご案内いただきます**ので、受け取った`アクセスキー`と`シークレットアクセスキー`、`セッショントークン`を手元にコピーしておいてください。


### HCP Terraform のアカウント開設
以下のアカウント開設リンクを開き、フォーム入力を進め`Create Account`ボタンを押します
https://app.terraform.io/public/signup/account
認証メールが届きますので、リンクをクリックし、Organizations作成ページに移動します。(**まだOrganizationsは作成しません**)

その状態で、HCP Terraform Plusエディションの機能を14日有効にする、トライアル用リンクを開きます。(別途ご案内します)

Businessのボックスにチェックをいれ、フォーム入力を進め、Organizationsの作成を完了してください。


## Terraform ハンズオン

### ゴール目標

本ハンズオンのゴールは、Terraform で ALB + EC2(MAZ)を、開発環境、本番環境の 2 面作ることです。理解のために、ステップバイステップで進めましょう。

![alt text](<images/スクリーンショット 2025-06-02 10.20.05.png>)

### HCP TerraformのWorkspaceを作成する

先ほど作成したOrganizationsにおいて、画面内の`Version Control Workflow`を選択します。
もし画面遷移をしてしまった場合は、左側メニュー`Workspaces`をクリック、右上の`New`から`Workspace`を選択します。

1. VCS選択画面で、`GitHub` > `GitHub.com`を選択します。
2. GitHub連携をするためのポップアップが出ます。出ない場合はブラウザの設定でポップアップを許可してください。
3. `Continue`をクリックします
4. リポジトリ選択画面になりますので、先ほど作成した`hcp-terraform-handson`リポジトリを選択します
5. 右下`Create`ボタンを押してWorkspaceの作成を完了します。

次に、HCP TerraformがAWSにリソースを作成するための、アクセスキーを設定します。

1. Workspace内の左側`Variables`メニューを開き、
`Workspace Variables`の`+ Add variable`ボタンをクリックします。
2. `Environment variable`のラジオボタン選択し、`Key`に`AWS_ACCESS_KEY_ID`を、`Value`に先ほどコピーしたアクセスキーを設定、`Add variable`をクリックします。
3. 同様の手順で、`AWS_SECRET_ACCESS_KEY`と`AWS_SESSION_TOKEN`の名前で、シークレットアクセスキーとセッショントークンを設定します。この際、`sensitive`にチェックを入れてください。

次のような見た目になっていれば大丈夫です。
![alt text](<スクリーンショット 2025-07-17 23.33.21.png>)

### 最小リソースの作成

EC2 を 1 台作成するコードを書いてみます。

![alt text](<images/スクリーンショット 2025-06-02 10.20.29.png>)


再度エディタで`main.tf`を開いてください。ここに Terraform のコードを書いていきましょう。

Terraform のコードは、非常にシンプルで、基本構文は以下の繰り返しです。

```
<BLOCK TYPE> "<BLOCK LABEL>" "<BLOCK LABEL>" {
 # Block body
 <IDENTIFIER> = <EXPRESSION> # Argument
}
```

具体例を見てみます。`main.tf`に以下を書いて、実行してみます。

```terraform
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
}


resource "aws_instance" "web_server" {
  # ここにコードを調べながら書いてみましょう(画面投影で解説します)
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance.html
}
```

`main.tf`を編集し終えたら、変更をpushします。

```bash
git commit -am "add ec2"
git push
```

HCP Terraformの`Runs`に移動すると、`Plan`が自動で走り、問題なければ`Apply`の承認待ちになっています。
`Confirm`をクリックし、承認コメントを入力して実行します。

`Apply`が完了した後にAWSコンソール上で見ると、名前がついていないことが確認できます。

![alt text](<images/スクリーンショット 2025-06-04 0.18.15.png>)

これでは不便なので、タグをつける変更を Terraform 経由で実行してみましょう。
ドキュメントを参考に、EC2の`resource`ブロックを編集します。

コード更新をしたら、再度pushします。

```bash
git commit -am "add tag to ec2"
git push
```

再度`Apply`承認待ちになっています。毎回確認が入るのが煩わしいので`Confirm`を進めたあと、自動で`Apply`されるように設定変更をしましょう。(このように、例えば開発環境は自動承認、本番環境は手動承認といった形で使い分けができます)

HCP TerraformのWorkspace内、左側メニューから`Settings` > `Version Control`に進み、`Auto-apply API, UI, & VCS runs`にチェックを入れた後、ページ最下部`Update VCS settings`を押します。


AWSコンソールに戻ると、無事タグがEC2に反映されています。

![alt text](<images/スクリーンショット 2025-06-04 0.24.32.png>)


### VPC を作成する

それでは、実用に近い構成を作っていきます。まずは VPC と関連リソースを作ります。

![alt text](<images/スクリーンショット 2025-06-02 10.20.23.png>)

先ほどの`main.tf`の中身を**全て削除**し、以下のコードに置き換えます

```terraform
# Provider設定
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 使用可能なAZを取得
data "aws_availability_zones" "available" {
  state = "available"
}

# 変数定義
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hcp-terraform-handson"
}


# VPC作成
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# インターネットゲートウェイ作成
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# パブリックサブネット1（AZ-a）
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
    Type = "Public"
  }
}

# パブリックサブネット2（AZ-c）
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
    Type = "Public"
  }
}

# パブリック・プライベート共通のルートテーブル
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-main-rt"
  }
}

# パブリックサブネット1とルートテーブルの関連付け
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.main.id
}

# パブリックサブネット2とルートテーブルの関連付け
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.main.id
}

# 出力値
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

コードを解説します。概要を掴んだら、変更をpushします。
```bash
git commit -am "create vpc and subnets"
git push
```

VPC とサブネットリソースが作成されました。

### EC2 を追加する

EC2 を MAZ 構成で追加します。

![alt text](<images/スクリーンショット 2025-06-02 10.20.18.png>)

先ほどの`main.tf`の一番最後に、次のコードを **追記** してください。

```terraform
# 最新のAmazon Linux 2023 AMIを取得
data "aws_ami" "amazon_linux2023" {
  most_recent = true
  owners      = ["137112412989"] 

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# セキュリティグループ
resource "aws_security_group" "ec2_sg" {
  name        = "hcp-terraform-handson-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# EC2インスタンス - パブリックサブネット1
resource "aws_instance" "public_1" {
  ami                    = data.aws_ami.amazon_linux2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = base64encode(local.nginx_userdata_1)

  tags = {
    Name = "${var.project_name}-ec2-public-1"
  }
}

# EC2インスタンス - パブリックサブネット2
resource "aws_instance" "public_2" {
  ami                    = data.aws_ami.amazon_linux2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = base64encode(local.nginx_userdata_2)

  tags = {
    Name = "${var.project_name}-ec2-public-2"
  }
}


# Nginx起動用userdata script
locals {
  nginx_userdata_1 = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    sed -i 's/x!/x!-01/g' /usr/share/nginx/html/index.html
  EOF

    nginx_userdata_2 = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    sed -i 's/x!/x!-02/g' /usr/share/nginx/html/index.html

  EOF
}

# EC2インスタンスのIPアドレスを出力
output "ec2_public_1_public_ip" {
  description = "Public IP of EC2 instance in public subnet 1"
  value       = aws_instance.public_1.public_ip
}

output "ec2_public_2_public_ip" {
  description = "Public IP of EC2 instance in public subnet 2"
  value       = aws_instance.public_2.public_ip
}
```
 
同様に解説します。概要が掴めたら、変更をpushしてください。
```bash
git commit -am "create multi AZ ec2"
git push
```


コードの前半には先ほどの VPC リソースが記載されていますが、そのまま実行しても追加分の EC2 だけ適切にリソースが作成されます。これは、Terraform が宣言的なコード記述ができる特性が現れていて、Day2 運用、構成変更に対しての利点となります。

### ALB を追加する

EC2 の手前に ALB を追加します。

![alt text](<images/スクリーンショット 2025-06-02 10.20.14.png>)

同様に、`main.tf`の最後に **追記** してください。

```terraform
# ALB用セキュリティグループ
resource "aws_security_group" "alb_sg" {
  name        = "hcp-terraform-handson-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# ターゲットグループにEC2インスタンスを登録
resource "aws_lb_target_group_attachment" "public_1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.public_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "public_2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.public_2.id
  port             = 80
}

# ALBリスナー
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALBのDNS名を出力
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}
```

変更をpushします。
```bash
git commit -am "add alb to ec2"
git push
```


同様に解説します。
作成が完了し、ALB の DNS 名がHCP Terraform上に出力されたらブラウザからアクセスしてみてください。
リロードを何回か繰り返すと、EC2 にラウンドロビンされている様子がわかると思います。

次の準備のために、環境を削除しましょう。少し環境が複雑になってきましたが、IaC では環境の削除も容易です。

HCP TerraformのWorkspace内、左側メニューから`Settings` > `Destruction and Deletion`に進み、`Queue destroy plan`を実行します。これは、Terraformで作成した環境の削除に相当します。

### 開発環境、本番環境をそれぞれ作る

最後に、この Terraform のコードを使って、本番と開発環境を作ってみましょう。冒頭に示した、最終ゴールのアーキテクチャです。

![alt text](<images/スクリーンショット 2025-06-02 10.20.05.png>)

AWSは環境分離に様々な方法がありますが、ここではリソースのタグベースでそれぞれの環境を作ることを試してみます。

リソース名に環境名を追加してみましょう。`main.tf`の32行目あたりに、次の変数定義を追加します。

```terraform
variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}
```

次に、`main.tf`を編集します。お使いのエディタの機能で、`${var.project_name}`となっている箇所を、`${var.project_name}-${var.environment}`と全て置換してください。手動でも大丈夫です。

終わりましたら、変数を外部から渡しましょう。同時に開発環境として設定してみます。

- HCP TerraformのWorkspace内左側メニュー`Variables` > `Workspace Variables`に移動し、`+ Add Variable`ボタンをクリックします
- `Terraform Variable`のカテゴリで、`Key`に`environment`、`Value`に`dev`を入力し`Add Variable`ボタンをクリックします
- 先ほど更新したコードをpushします
```bash
git commit -am "add env variable"
git push
```

次に、本番環境の設定してみます。HCP Terraformでは環境ごとにWorkspaceを分けるのがプラクティスです。これまでの手順を参考に、新規のWorkspaceを作り、`environment`変数に`prod`を渡すところまでやってみましょう。

(参考：手順の流れ)
- Workspaceの作成
- GitHubと連携し`hcp-terraform-handson`を選択
- AWSのアクセスキーの設定
- `environment`変数に`prod`を設定
- 作成したworkspace内の`Runs`から、`+ New run`でPlanとApplyを実行

TerraformのApplyが完了するまで待った後、コンソールから見ると、それぞれ開発と本番環境がタグ名で分離して作成されていることが確認できます。このように、変数やコードを再利用性のある形で相互利用することにより、容易に環境の用意と削除が実行できます。

### (発展編) Policy as Codeでガードレールを実装する

各リソースが従うべきルールを、同じくコードで実装することが可能です。例えば
- 本番環境は金曜夕方〜月曜朝までのリソース変更を認めない
- 開発環境はt3系のインスタンスのみ使う
- セキュリティグループの22番ポートは社内のIPアドレスをソースにする


などが考えられます。これらを「ルールとして人にお願いする」のではなく、実装として織り込んで機械的に強制することが出来るのがPolicy as Codeの利点です。

ここでは、シンプルに`t3.micro以外のインスタンスは許可されない`を実装してみましょう。

- HCP TerraformのWorkspaceの一覧を開き、左側メニューから`Settings` > `Policies`に進み、`Create New Policy`をクリックします
- 任意の名前をつけ、画面真ん中の`Policy code`と書かれているエディタに次のコードを貼り付けたら、一番下の`Create policy`をクリックします

```sentinel
import "tfplan/v2" as tfplan

main = rule {
    all tfplan.resource_changes as _, changes {
        changes.type != "aws_instance" or
        changes.change.after.instance_type == "t3.micro"
    }
}
```

- 同じく左側の`Policy sets`メニューから`Connect a new policy set`ボタンをクリックします
- `Individually managed policies`を選び、任意の名前をつけた後、`Scope of policies`から`Policies enforced on selected projects and workspaces`を選択します
- ProjectとWorkspaceを選んだら、一番下の`Next`をクリックします
- 最後に`Policies`から直前で作ったポリシーを選択し`Connect policy set`をクリックします

これで特定のワークスペースに対するポリシーの設定が環境しました。Terraformのコードに戻り、試しにインスタンスのサイズをm5.largeに変更してプッシュしてみましょう。

HCP TerraformのWorkspaceに移動し、`Runs`をみてみると、このポリシーにより変更がブロックされているのが確認できるかと思います。
![alt text](<スクリーンショット 2025-07-18 1.29.18.png>)

## 片付け

### 作成したリソースの削除

HCP Terraformの**各Workspace**内、左側メニューから`Settings` > `Destruction and Deletion`に進み、`Queue destroy plan`を実行します。


