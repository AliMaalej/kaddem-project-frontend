FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY dist/exam1/ .
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
