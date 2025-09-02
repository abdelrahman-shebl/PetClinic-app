# Use a very small base image
FROM nginx:alpine

# Replace the default index page
RUN echo "Hello from my CI/CD pipeline 🚀" > /usr/share/nginx/html/index.html

# Expose port
EXPOSE 80
