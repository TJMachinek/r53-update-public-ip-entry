FROM amazon/aws-cli:latest
ADD ./dynamic_dns_r53.sh /aws/dynamic_dns_r53.sh
ENTRYPOINT ["/aws/dynamic_dns_r53.sh"]