FROM public.ecr.aws/lambda/python:3.7

COPY requirements.txt ./
RUN python3.7 -m pip install -r requirements.txt -t .

COPY data_loader ./data_loader
COPY model ./model
COPY utils ./utils
COPY memcache.py ./
COPY storage ./storage
COPY communicator ./communicator
COPY linear_ec_2.py ./

CMD ["linear_ec_2.handler"]
