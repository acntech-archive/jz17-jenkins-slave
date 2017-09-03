FROM openjdk:8-jdk

ENV DOCKERIZE_VERSION v0.5.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

#
# Install Maven
#
ARG MAVEN_VERSION=3.5.0
ARG USER_HOME_DIR="/root"

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

#
# Node and Npm
#
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

#
# Install Docker
#
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 17.06.0-ce

RUN set -ex \
	&& curl -fL -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" \
	&& tar --extract \
			--file docker.tgz \
			--strip-components 1 \
			--directory /usr/local/bin/ \
	&& rm docker.tgz \
	&& docker -v

#
# Install Docker Compose
#
RUN curl -L https://github.com/docker/compose/releases/download/1.16.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

#
# Jenkins stuff
#
ENV HOME /home/jenkins
RUN groupadd -g 10000 jenkins
RUN useradd -c "Jenkins user" -d $HOME -u 10000 -g 10000 -m jenkins

# Create Docker group (gid 999 from the Ubuntu Hosts) and add jenkins user to it
RUN groupadd -g 999 docker && usermod -a -G docker jenkins

ARG JENKINS_REMOTE_VERSION=3.9
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_REMOTE_VERSION}/remoting-${JENKINS_REMOTE_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

# Add ssh keys for jenkins user
COPY ssh /home/jenkins/.ssh
RUN chown jenkins:jenkins /home/jenkins/ -R
RUN chmod 0600 /home/jenkins/.ssh/id_rsa

# Copy entrypoint and run as jenkins
COPY jenkins-slave /usr/local/bin/jenkins-slave
USER jenkins

# Create Jenkins slave root and set workdir
RUN mkdir /home/jenkins/.jenkins
VOLUME /home/jenkins/.jenkins
WORKDIR /home/jenkins

ENTRYPOINT ["jenkins-slave"]