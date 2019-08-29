FROM bitnami/python:3.7-prod

# Change this when the version changes
ARG WCT_VERSION=1.2.3
ENV WCT_VERSION=${WCT_VERSION}

ENV PATH_TO_DATA_FILE=/project/wct_app/data

RUN pip install --upgrade pip
COPY ./wct_app/requirements.txt /project/wct_app/requirements.txt
RUN	pip install --no-cache  -r /project/wct_app/requirements.txt

COPY ./wct_app /project/wct_app

WORKDIR /project

EXPOSE 8000

ARG SECRET_SAUCE_ARG=7
ENV SECRET_SAUCE=${SECRET_SAUCE_ARG}

CMD gunicorn -b 0.0.0.0:8000 -w 4 --log-level debug wct_app.main.app:APP
