FROM bitnami/python

ENV SECRET_SAUCE=7
ENV WCT_VERSION=1.2.4
ENV PATH_TO_DATA_FILE=/wct_app/data

RUN pip install --upgrade pip
COPY ./wct_app/requirements.txt /tmp/requirements.txt
RUN	pip install --no-cache  -r /tmp/requirements.txt

COPY ./ /

WORKDIR /

EXPOSE 8000

#gunicorn -D -w 4 --log-level debug --capture-output --error-logfile errors.log wct_app.main.app:APP
CMD gunicorn  -D -w 4 --log-level debug --capture-output --error-logfile errors.log  wct_app.main.app:APP
