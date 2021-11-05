FROM amazon/aws-cli:latest
RUN yum update -y \
    && yum install jq -y \
    && yum clean all
ADD ./dynamic_dns_r53.sh /aws/dynamic_dns_r53.sh
ENTRYPOINT ["/aws/dynamic_dns_r53.sh"]