FROM locustio/locust

ADD . /locust

RUN pip3 install --upgrade pip

USER locust

RUN pip3 install locust

USER root

EXPOSE 5557 5558 8089

RUN chmod 755 /locust/run.sh

ENTRYPOINT ["/locust/run.sh"]
