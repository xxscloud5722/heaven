FROM registry.cn-shanghai.aliyuncs.com/basis/crontab:1.0.1
ADD ./nacos.sh /opt/nacos.sh
ADD ./scan.sh /opt/scan.sh
ADD ./k8s.sh /opt/k8s.sh
ADD ./confluence.sh /opt/confluence.sh
ADD ./zentao.sh /opt/zentao.sh
ADD ./showdoc.sh /opt/showdoc.sh
ADD ./nfs.sh /opt/nfs.sh
ADD ./domain.sh /opt/domain.sh
ADD ./domain /opt/domain

ADD ./tencent_cos.sh /opt/tencent_cos.sh

ADD ./aliyun /opt/aliyun
ADD ./kubectl /opt/kubectl
ADD ./coscli /opt/coscli
RUN chmod +x /opt/* && mkdir /opt/logs
WORKDIR /opt