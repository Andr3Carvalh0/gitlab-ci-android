#
# GitLab CI: Android v0.3k
#
# Based of: 
# https://hub.docker.com/r/jangrewe/gitlab-ci-android/
# https://git.faked.org/jan/gitlab-ci-android
#

FROM ubuntu:18.04
MAINTAINER Andre Carvalho <andre.b.carvalho@accenture.com>

ENV VERSION_TOOLS "6200805"

ENV ANDROID_HOME "/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update \
 && apt-get install -qqy --no-install-recommends \
      bzip2 \
      curl \
      git-core \
      html2text \
      openjdk-8-jdk \
      libc6-i386 \
      lib32stdc++6 \
      lib32gcc1 \
      lib32ncurses5 \
      lib32z1 \
      unzip \
      locales \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip > /tools.zip \
 && mkdir -p ${ANDROID_HOME}/cmdline-tools \
 && unzip /tools.zip -d ${ANDROID_HOME}/cmdline-tools \
 && rm -v /tools.zip

RUN mkdir -p $ANDROID_HOME/licenses/ \
 && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
 && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license \
 && yes | ${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} --licenses >/dev/null

ADD packages.txt /sdk
RUN mkdir -p /root/.android \
 && touch /root/.android/repositories.cfg \
 && ${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} --update

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < /sdk/packages.txt \
 && ${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} ${PACKAGES}

RUN curl -sL https://firebase.tools | sed 's#sudo##g' | upgrade=true bash

RUN apt-get -qq update \
 && apt-get install -qqy --no-install-recommends build-essential ruby-full

RUN gem update --system

RUN gem install fastlane -NV bundler fastlane-plugin-firebase_app_distribution fastlane-plugin-appcenter

ARG GRADLE_VERSION=6.1.1
ARG GRADLE_BASE_URL=https://services.gradle.org/distributions

RUN mkdir -p /usr/share/gradle /usr/share/gradle/ref \
  && curl -fsSL -o /tmp/gradle.zip ${GRADLE_BASE_URL}/gradle-${GRADLE_VERSION}-bin.zip \
  && unzip -d /usr/share/gradle /tmp/gradle.zip \
  && rm -f /tmp/gradle.zip \
  && ln -s /usr/share/gradle/gradle-${GRADLE_VERSION} /usr/bin/gradle

# 5- Define environmental variables required by gradle
ENV GRADLE_VERSION 6.1.1
ENV GRADLE_HOME /usr/bin/gradle
ENV GRADLE_USER_HOME /cache

ENV PATH $PATH:$GRADLE_HOME/bin
