FROM public.ecr.aws/lambda/python:3.7

COPY requirements.txt ./
RUN python3.7 -m pip install -r requirements.txt -t .

COPY linear_ec_1.py ./

CMD ["linear_ec_1.handler"]
