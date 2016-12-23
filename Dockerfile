FROM ubuntu:14.04
MAINTAINER Erick Almeida <ephillipe@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

# Add multiverse repo and upgrade system
ADD ./sources.list /etc/apt/sources.list
RUN apt-get -y update \
    && apt-get -y dist-upgrade

RUN echo 'Dpkg::Progress-Fancy "1";' > /etc/apt/apt.conf.d/99progressbar

# Install PPA for LibreOffice 4.4 and libsslAnchor link for: install ppa for libreoffice 44 and libssl
RUN apt-get install -yq vim figlet wget software-properties-common \
    && add-apt-repository -y ppa:libreoffice/libreoffice-4-4 \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -yq --allow-unauthenticated libssl1.0.2

RUN apt-get install -yq language-pack-en \
    && update-locale LANG=en_US.UTF-8

# Install ffmpeg
ADD scripts/ffmpeg.sh /tmp
RUN apt-get install -yq --allow-unauthenticated build-essential git-core checkinstall yasm texi2html libvorbis-dev libx11-dev libvpx-dev libxfixes-dev zlib1g-dev pkg-config netcat libncurses5-dev \
    && chmod a+x /tmp/ffmpeg.sh \
    && cd /tmp \
    && bash ffmpeg.sh
RUN ffmpeg -version

# Install Tomcat prior to bbb installation
RUN apt-get install -y tomcat7
# Replace init script, installed one is broken
ADD scripts/tomcat7 /etc/init.d/

# http://docs.bigbluebutton.org/install/install.html#install-bigbluebutton
# Add the BigBlueButton key
RUN wget http://ubuntu.bigbluebutton.org/bigbluebutton.asc -O- | apt-key add -
# Add the BigBlueButton repository URL and ensure the multiverse is enabled
RUN echo "deb http://ubuntu.bigbluebutton.org/trusty-1-0/ bigbluebutton-trusty main" | tee /etc/apt/sources.list.d/bigbluebutton.list
RUN apt-get -y update \
    && apt-get install -y --allow-unauthenticated bigbluebutton \
    && bbb-conf --enablewebrtc

# http://docs.bigbluebutton.org/install/install.html#imagemagick-security-issues
ADD ImageMagick_policy.xml /etc/ImageMagick/policy.xml
RUN convert -list policy

EXPOSE 80 9123 1935

#Add helper script to start bbb
ADD scripts/bbb-start.sh /usr/bin/

CMD ["/usr/bin/bbb-start.sh"]
