
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
  - [Policy as Codeでガードレールを実装する](#policy-as-codeでガードレールを実装する)
  - [マルチプラットフォームをTerraformで管理する](#マルチプラットフォームをterraformで管理する)
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
本設定は**AWSのサインインポータルからコピー**しますので、その`アクセスキー`と`シークレットアクセスキー`、`セッショントークン`を手元にエディタなどにペーストしておいてください。


### HCP Terraform のアカウント開設
以下のアカウント開設リンクを開き、フォーム入力を進め`Create Account`ボタンを押します。

https://app.terraform.io/public/signup/account

認証メールが届きますので、リンクをクリックし、Organizations作成ページに移動します。(**まだOrganizationsは作成しません**)

その状態で、HCP Terraform Plusエディションの機能を14日有効にする、トライアル用リンクを開きます。(別途ご案内します)

Businessのボックスにチェックをいれ、フォーム入力を進め、Organizationsの作成を完了してください。


## Terraform ハンズオン

### ゴール目標

本ハンズオンのゴールは2つです。
1. Terraform で ALB + EC2(MAZ)を、開発環境、本番環境の 2 面作ることで、複雑な環境をコードを通じて作成、管理することを学ぶ
2. AWS以外のSaaSも合わせてTerraformで作成し、マルチプラットフォームを1つの仕組みを通じて自動化することを学ぶ


理解のために、ステップバイステップで進めましょう。

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
![alt text](<images/スクリーンショット 2025-07-17 23.33.21.png>)

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
  region  = "us-west-2"
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
  default     = "us-west-2"
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

### Policy as Codeでガードレールを実装する

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

これで特定のワークスペースに対するポリシーの設定が環境しました。Terraformのコードに戻り、試しにインスタンスのサイズを`m5.large`に変更してプッシュしてみましょう。

HCP TerraformのWorkspaceに移動し、`Runs`をみてみると、このポリシーにより変更がブロックされているのが確認できるかと思います。
![alt text](<images/スクリーンショット 2025-07-18 1.29.18.png>)

## マルチプラットフォームをTerraformで管理する
これまでの`main.tf`の中身をすべて削除し、以下に置き換えたあと`apply`します。

```terraform
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# 変数
#   ハンズオンを同一 AWS アカウント / 同一デフォルトVPC で複数人が同時に実施する
#   ことを想定した識別子。
#   HCP Terraform を使う場合 state はワークスペースごとに分離されるが、AWS 側の
#   実体は共有されるため、名前が衝突するリソースには識別子を付けて分ける必要が
#   ある。特にセキュリティグループ名は VPC 内で一意でなければならず、未対応だと
#   2人目の apply が InvalidGroup.Duplicate で失敗する。
# -----------------------------------------------------------------------------
variable "owner" {
  description = <<-EOT
    リソース名・タグに付与する作業者識別子。
    同一アカウント/VPC で複数人が実施する際の名前衝突と、
    コンソール上での所有者判別のために使用する。
    HCP Terraform ではワークスペース変数として各自設定する。
    例: "tomochika"
  EOT
  type        = string

  # SG 名やタグに埋め込むため、AWS の命名で安全に使える文字種に限定する。
  # デフォルト値は意図的に設けない (全員が同じ値で走って衝突するのを防ぐため)。
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,29}$", var.owner))
    error_message = "owner は英小文字・数字・ハイフンのみ、1〜30文字、先頭は英数字にしてください。"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# デフォルト VPC を利用（最小構成のため）
data "aws_vpc" "default" {
  default = true
}

# 最新の Amazon Linux 2023 AMI を取得
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  # 標準(フル)の AL2023 AMI に限定。"al2023-ami-2023*" は minimal を除外できる
  # t4g 系は ARM(Graviton) のため arm64 の AMI を使用する
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Grafana(3000番ポート)への外部アクセスを許可するセキュリティグループ
# 名前は VPC 内で一意である必要があるため var.owner を付与する。
resource "aws_security_group" "grafana" {
  name        = "grafana-sg-${var.owner}"
  description = "Allow Grafana web access"
  vpc_id      = data.aws_vpc.default.id

  # 3000 番は 0.0.0.0/0 で開ける必要がある。
  # 理由: HCP Terraform でリモート実行する場合、grafana provider の API 接続は
  # 手元のPCではなく HCP のランナーから発生するため、送信元IPを自分に絞ると
  # apply が到達不能で失敗する。
  ingress {
    description = "Grafana web UI"
    from_port   = 3000
    to_port     = 3000
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
    Name  = "grafana-sg-${var.owner}"
    Owner = var.owner
  }
}

# 既存の SSM 用インスタンスプロファイルを参照。
# ハンズオン環境に AmazonSSMManagedInstanceCore が存在しない場合は解決に失敗するため
# 既定ではコメントアウトしている。存在する環境では以下と、各 aws_instance の
# iam_instance_profile 行のコメントを外すと SSM セッションマネージャが利用できる。
# data "aws_iam_instance_profile" "ssm" {
#   name = "AmazonSSMManagedInstanceCore"
# }

resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t4g.small"
  vpc_security_group_ids      = [aws_security_group.grafana.id]
  associate_public_ip_address = true

  # SSM を使う場合はコメントを外す (上記 data ブロックも合わせて有効化する)
  # iam_instance_profile = data.aws_iam_instance_profile.ssm.name

  # Grafana をインストールして起動
  # 注意: <<-EOF はタブのインデントのみ除去しスペースは残るため、
  # shebang(#!) の前に空白が入り "Exec format error" になる。
  # そのため通常の <<EOF を使い、行頭は左詰めで記述する。
  user_data = <<EOF
#!/bin/bash
set -euxo pipefail

# SSM Agent が未インストールなら導入し、起動・自動起動を有効化（冪等）
if ! systemctl list-unit-files | grep -q '^amazon-ssm-agent\.service'; then
  dnf install -y amazon-ssm-agent
fi
systemctl enable --now amazon-ssm-agent

tee /etc/yum.repos.d/grafana.repo > /dev/null <<'REPO'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
REPO

dnf install -y grafana

# 初期 admin パスワードを設定（初回ログイン時のパスワード変更要求を回避）
# 注意: 平文で user_data / tfstate に残るため学習用途のみ。本番では利用しない。
tee -a /etc/sysconfig/grafana-server > /dev/null <<'ENVV'
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=Handson0911!
ENVV

systemctl enable --now grafana-server
EOF

  tags = {
    Name  = "grafana-instance-${var.owner}"
    Owner = var.owner
  }
}

# Grafana provider の接続設定。
# ec2-grafana.tf ではなく main.tf に置いている理由:
#   ec2-grafana.tf を .tf 以外にリネームして無効化したときに provider 設定まで
#   消えてしまうと、state に残った grafana リソース (データソース/ダッシュボード)
#   を削除できず "the Grafana client is required for this resource" となるため。
#   provider 設定を常に有効にしておくことで、リネームによる削除が正しく動く。
provider "grafana" {
  # 上で作成した Grafana インスタンスのパブリックIP:3000 を参照
  url = "http://${aws_instance.grafana.public_ip}:3000"
  # basic auth 形式 "username:password"
  auth = "admin:Handson0911!"

  # Grafana 起動直後は API 応答が不安定なことがあるためリトライを緩める
  retries    = 10
  retry_wait = 15
}

output "grafana_url" {
  description = "Grafana にアクセスする URL"
  value       = "http://${aws_instance.grafana.public_ip}:3000"
}

```
Grafanaダッシュボードのアドレスが出力されるので、ブラウザでアクセスし問題なく表示されることを確認します。(admin/Handson0911!でログイン)

次に、`ec2.tf`を作成し、以下の内容をペーストし、同じく`apply`します。

```terraform
# =============================================================================
# ec2-grafana.tf
#
# 目的:
#   新規 EC2 を1台作成し、その EC2 自身に
#     - node_exporter (ホストのCPU/メモリ等を 9100 番で公開)
#     - Prometheus    (localhost の node_exporter を 9090 番でスクレイプ)
#   を同居させる。
#   その上で、既存の Grafana (main.tf で起動済み) に対して
#     - Prometheus データソース
#     - この EC2 のCPU/メモリ使用率ダッシュボード
#   を Grafana provider 経由で新規作成する。
#
#   => `terraform apply` 一発で「新規EC2作成」と「Grafana専用ダッシュボード作成」
#      が同時に実行される。
#
# 接続経路 (パターンA):
#   Grafana サーバー(EC2) --(VPC内, proxy)--> 新規EC2:9090 (Prometheus)
#   データソース URL には新規EC2のプライベートIPを使用。
#   9090 は外部公開せず、送信元を Grafana の SG に限定する。
#
# 前提:
#   - main.tf は変更しない。
#   - Grafana は既に起動済み。URL = http://<grafana_public_ip>:3000
#     認証情報 = admin / Handson0911!
# =============================================================================

# -----------------------------------------------------------------------------
# Provider について
#   grafana provider の required_providers と provider 設定 (接続先/認証) は
#   main.tf 側に定義している。
#   理由: このファイルを .tf 以外にリネームして無効化した際、provider 設定まで
#   消えると state に残る grafana リソースを削除できず
#   "the Grafana client is required for this resource" エラーになるため。
# -----------------------------------------------------------------------------
# 監視対象となる新規 EC2 用セキュリティグループ
#   - 9090 (Prometheus): 送信元を Grafana の SG に限定 (VPC内 proxy アクセス用)
#   - node_exporter(9100) は localhost スクレイプのため外部開放不要
#   - 22 (SSH): デバッグ用にログインできるよう許可する
# -----------------------------------------------------------------------------
# 名前は VPC 内で一意である必要があるため var.owner を付与する。
resource "aws_security_group" "monitored_target" {
  name        = "monitored-target-sg-${var.owner}"
  description = "Allow Prometheus scrape from Grafana server within VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Prometheus HTTP from Grafana server"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  # デバッグ用の SSH。全世界に開いているため、ハンズオン以外では
  # cidr_blocks を自分のIP (x.x.x.x/32) に絞ることを推奨。
  ingress {
    description = "SSH for debugging"
    from_port   = 22
    to_port     = 22
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
    Name  = "monitored-target-sg-${var.owner}"
    Owner = var.owner
  }
}

# -----------------------------------------------------------------------------
# 監視対象の新規 EC2
#   node_exporter + Prometheus を user_data でインストール・起動する。
#   AMI は main.tf の data ソースを再利用する。
#   IAM インスタンスプロファイルと SSH キーペアは既定では付与しない
#   (ハンズオン環境に該当ロールが無い / キーペア名が環境依存のため)。
#   必要な場合は下のコメントを外して使う。
#   (data.aws_ami.amazon_linux は arm64 AL2023 なので arm64 バイナリを使う)
# -----------------------------------------------------------------------------
resource "aws_instance" "monitored_target" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t4g.small"
  vpc_security_group_ids      = [aws_security_group.monitored_target.id]
  associate_public_ip_address = true

  # SSM を使う場合はコメントを外す (main.tf の data ブロックも合わせて有効化する)
  # iam_instance_profile = data.aws_iam_instance_profile.ssm.name

  # SSH でログインする場合はコメントを外し、既存のキーペア名を指定する
  # key_name = "your-key-pair-name"

  # 注意1: <<-EOF はタブのみ除去。shebang前に空白が入らないよう左詰めで記述。
  # 注意2: user_data 内で bash のシェル変数を使う箇所は、Terraform の補間
  #        (${...}) と衝突するため $${...} とエスケープしている。Terraform は
  #        $${ をリテラルの ${ に変換して EC2 へ渡す。このスクリプト内に
  #        Terraform 側の値注入は無い。
  user_data = <<EOF
#!/bin/bash
set -euxo pipefail

# --- 共通: アーキテクチャ判定 (t4g = arm64) -----------------------------------
ARCH=arm64

# --- node_exporter インストール -----------------------------------------------
NODE_EXPORTER_VERSION=1.8.2
useradd --no-create-home --shell /sbin/nologin node_exporter || true
cd /tmp
curl -fsSL -o node_exporter.tar.gz \
  "https://github.com/prometheus/node_exporter/releases/download/v$${NODE_EXPORTER_VERSION}/node_exporter-$${NODE_EXPORTER_VERSION}.linux-$${ARCH}.tar.gz"
tar xzf node_exporter.tar.gz
cp "node_exporter-$${NODE_EXPORTER_VERSION}.linux-$${ARCH}/node_exporter" /usr/local/bin/node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

tee /etc/systemd/system/node_exporter.service > /dev/null <<'UNIT'
[Unit]
Description=Prometheus Node Exporter
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
# localhost のみで待受 (外部公開しない)
ExecStart=/usr/local/bin/node_exporter --web.listen-address=127.0.0.1:9100

[Install]
WantedBy=multi-user.target
UNIT

# --- Prometheus インストール --------------------------------------------------
PROMETHEUS_VERSION=2.53.1
useradd --no-create-home --shell /sbin/nologin prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus
cd /tmp
curl -fsSL -o prometheus.tar.gz \
  "https://github.com/prometheus/prometheus/releases/download/v$${PROMETHEUS_VERSION}/prometheus-$${PROMETHEUS_VERSION}.linux-$${ARCH}.tar.gz"
tar xzf prometheus.tar.gz
cd "prometheus-$${PROMETHEUS_VERSION}.linux-$${ARCH}"
cp prometheus promtool /usr/local/bin/
cp -r consoles console_libraries /etc/prometheus/
chown -R prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool /etc/prometheus /var/lib/prometheus

# Prometheus 設定: localhost の node_exporter をスクレイプ
tee /etc/prometheus/prometheus.yml > /dev/null <<'PROMYML'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['127.0.0.1:9100']
PROMYML
chown prometheus:prometheus /etc/prometheus/prometheus.yml

tee /etc/systemd/system/prometheus.service > /dev/null <<'UNIT'
[Unit]
Description=Prometheus
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
# Grafana サーバー(VPC内)からの proxy アクセスを受けるため 0.0.0.0 で待受
# 外部公開はセキュリティグループ側で 9090 を Grafana SG に限定して防ぐ
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target
UNIT

# --- 起動 ---------------------------------------------------------------------
systemctl daemon-reload
systemctl enable --now node_exporter
systemctl enable --now prometheus
EOF

  tags = {
    Name  = "monitored-target-instance-${var.owner}"
    Owner = var.owner
  }
}

# -----------------------------------------------------------------------------
# Grafana: Prometheus データソース
#   URL は新規EC2のプライベートIP:9090 (VPC内 proxy アクセス)
#   Grafana サーバーがこの URL に到達する。
# -----------------------------------------------------------------------------
resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "prometheus-monitored-target"
  url  = "http://${aws_instance.monitored_target.private_ip}:9090"

  # Grafana サーバー経由でアクセス (パターンA)
  access_mode = "proxy"
  is_default  = false

  json_data_encoded = jsonencode({
    httpMethod = "POST"
  })

  # 依存を明示 (インスタンス起動 → Prometheus 起動まで多少ラグがあるが、
  # データソース登録自体は接続テストをしないため作成順序のみ担保する)
  depends_on = [aws_instance.monitored_target]
}

# -----------------------------------------------------------------------------
# Grafana: 専用ダッシュボード (CPU / メモリ使用率)
#   node_exporter のメトリクスから使用率を算出:
#     - CPU使用率  : 100 - (idle CPU の割合)
#     - メモリ使用率: (1 - MemAvailable / MemTotal) * 100
# -----------------------------------------------------------------------------
resource "grafana_dashboard" "monitored_target" {
  config_json = jsonencode({
    uid           = "monitored-target-metrics"
    title         = "Monitored Target - CPU / Memory"
    schemaVersion = 39
    version       = 1
    refresh       = "10s"
    time = {
      from = "now-1h"
      to   = "now"
    }
    templating  = { list = [] }
    annotations = { list = [] }
    panels = [
      {
        id      = 1
        type    = "timeseries"
        title   = "CPU使用率 (%)"
        gridPos = { h = 9, w = 12, x = 0, y = 0 }
        datasource = {
          type = "prometheus"
          uid  = grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit = "percent"
            min  = 0
            max  = 100
          }
          overrides = []
        }
        targets = [
          {
            refId        = "A"
            expr         = "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
            legendFormat = "CPU使用率"
          }
        ]
      },
      {
        id      = 2
        type    = "timeseries"
        title   = "メモリ使用率 (%)"
        gridPos = { h = 9, w = 12, x = 12, y = 0 }
        datasource = {
          type = "prometheus"
          uid  = grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit = "percent"
            min  = 0
            max  = 100
          }
          overrides = []
        }
        targets = [
          {
            refId        = "A"
            expr         = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
            legendFormat = "メモリ使用率"
          }
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# 出力
# -----------------------------------------------------------------------------
output "monitored_target_private_ip" {
  description = "監視対象EC2のプライベートIP (Prometheus:9090)"
  value       = aws_instance.monitored_target.private_ip
}

output "grafana_dashboard_url" {
  description = "作成した専用ダッシュボードのURL"
  value       = "http://${aws_instance.grafana.public_ip}:3000/d/${grafana_dashboard.monitored_target.uid}"
}

```

ec2作成と同時に、ダッシュボードも新規に用意されることが確認できます。
また、`ec2.tf`を`ec2.tf.disabled`等と名前を変え削除状態を模擬し、再度`apply`すると、ec2とダッシュボードが削除されることが確認できます。
こうして、マルチプラットフォーム管理をTerraformで統一できることがわかりますね。

## 片付け

### 作成したリソースの削除

HCP Terraformの**各Workspace**内、左側メニューから`Settings` > `Destruction and Deletion`に進み、`Queue destroy plan`を実行します。


