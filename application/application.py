from flask import Flask

application = Flask(__name__)

@application.route("/")
def hello():
    import os
    ip = os.getenv('INTERNAL_IP')
    return f"<h1>Hello There!</h1>\n<p>The Internal IP address is {ip}<\p>"

  if __name__ == "__main__":
    application.run(host='0.0.0.0', port=5000, debug=True)
