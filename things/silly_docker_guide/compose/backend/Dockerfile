FROM golang:1.22-alpine

WORKDIR /app

COPY main.go .

RUN go mod init main
RUN go build -o main .

EXPOSE 3000

CMD ["./main"]
