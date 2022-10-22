from diagrams import Diagram, Cluster
from diagrams.aws.compute import ECS, Lambda
from diagrams.aws.security import ACM
from diagrams.aws.network import ALB, NATGateway, InternetGateway
from diagrams.aws.mobile import APIGateway


with Diagram("SpiceDB Authorizer", show=False):
  api = APIGateway("API Gateway")
  with Cluster("VPC"):
    alb = ALB("ALB")
    igw = InternetGateway("internet gateway")
    with Cluster("public subnet"):
      nat = NATGateway("")
      nat >> igw
    with Cluster("private subnet"):
      spicedb = ECS("test")
      authorizer = Lambda("spicedb-authorizer")
      initializer = Lambda("initializer")
      alb >> spicedb
      spicedb >> nat
      authorizer >> nat
      initializer >> nat

      alb << authorizer
      alb << initializer

      api >> authorizer

