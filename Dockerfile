FROM node:lts

RUN export debian_frontend=NONINTERACTIVE \
    && apt-get update && apt-get install -y udev \ 
    && apt-get autoclean -y && apt-get autoremove -y \
    && npm i npm@latest -g \
    && npm install -g cncjs@latest --unsafe-perm

EXPOSE 8000/tcp
CMD ["/usr/local/bin/cncjs -w /fileshare"]

