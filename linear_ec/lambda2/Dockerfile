FROM python:3.7

COPY requirements.txt ./
RUN python3.7 -m pip install -r requirements.txt -t .
RUN mkdir -p /app/data

COPY data_loader ./data_loader
COPY model ./model
COPY utils ./utils
COPY memcache.py ./
COPY storage ./storage
COPY communicator ./communicator
COPY linear_ec_2.py ./
COPY test_input_worker0.json ./
COPY test_input_worker1.json ./

CMD ["python", "linear_ec_2.py"]