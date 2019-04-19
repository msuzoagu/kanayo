From  msuzoagu/kanayo:latest
Label maintainer="youremail"

RUN       mkdir -p /home/docker_user_name/configuration
COPY      /configuration /home/docker_user_name/configuration
CMD       ["/bin/sh"]
