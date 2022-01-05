FROM python:3.7

ARG INTERNAL_IP

ENV INTERNAL_IP $INTERNAL_IP

RUN mkdir /application

COPY . /application

WORKDIR /application

RUN pip install -r requirements.txt