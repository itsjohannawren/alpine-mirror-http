FROM alpine:3.16
EXPOSE 80/tcp
VOLUME /data /logs
RUN apk add --no-cache bash lighttpd && mkdir /templates
COPY lighttpd.conf /templates/lighttpd.conf
COPY entrypoint.sh /entrypoint.sh
HEALTHCHECK --start-period=10s --interval=5s --timeout=3s --retries=3 CMD /healthcheck.sh
ENTRYPOINT ["/entrypoint.sh"]
