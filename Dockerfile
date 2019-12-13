FROM python:3.6-alpine

RUN apk add git curl bash tar grep --no-cache

WORKDIR /app

COPY ./requirements.txt ./

# Pylint needs typed-ast which cannot provide a binary wheel distribution
# for musl based Alpine Linux. We need gcc to compile typed-ast.
RUN apk add --no-cache --virtual .typed_ast_deps gcc build-base && \
    pip install -r requirements.txt && \
    apk del .typed_ast_deps

COPY . .

ENTRYPOINT ["./project-checker.py"]
