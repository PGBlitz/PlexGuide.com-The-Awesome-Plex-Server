from flask import Flask, render_template, jsonify, request
import os
import subprocess

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/get-yml-files')
def get_yml_files():
    ymals_dir = '/pg/ymals/'
    try:
        files = sorted([f for f in os.listdir(ymals_dir) if os.path.isdir(os.path.join(ymals_dir, f))])
        return jsonify(files=files)
    except Exception as e:
        return jsonify(files=[], error=str(e))

@app.route('/get-yml-content/<folder>')
def get_yml_content(folder):
    yml_file = f'/pg/ymals/{folder}/docker-compose.yml'
    try:
        with open(yml_file, 'r') as file:
            content = file.read()
        return jsonify(content=content)
    except Exception as e:
        return jsonify(content=f"Error loading {yml_file}: {str(e)}")

@app.route('/save-yml/<folder>', methods=['POST'])
def save_yml(folder):
    yml_file = f'/pg/ymals/{folder}/docker-compose.yml'
    try:
        content = request.json.get('content')
        with open(yml_file, 'w') as file:
            file.write(content)
        return jsonify(success=True)
    except Exception as e:
        return jsonify(success=False, error=str(e))

@app.route('/check-docker-status/<folder>')
def check_docker_status(folder):
    try:
        result = subprocess.run(['docker', 'ps', '--filter', f'name={folder}', '--format', '{{.Names}}'], capture_output=True, text=True)
        if folder in result.stdout:
            return jsonify(running=True)
        else:
            return jsonify(running=False)
    except Exception as e:
        return jsonify(running=False, error=str(e))

@app.route('/deploy-yml/<folder>', methods=['POST'])
def deploy_yml(folder):
    yml_dir = f'/pg/ymals/{folder}'
    try:
        result = subprocess.run(['docker-compose', '-f', f'{yml_dir}/docker-compose.yml', 'up', '-d'], capture_output=True, text=True)
        return jsonify(success=True, output=result.stdout)
    except Exception as e:
        return jsonify(success=False, error=str(e))

@app.route('/kill-yml/<folder>', methods=['POST'])
def kill_yml(folder):
    yml_dir = f'/pg/ymals/{folder}'
    try:
        # Stop and remove the container
        result = subprocess.run(['docker-compose', '-f', f'{yml_dir}/docker-compose.yml', 'down'], capture_output=True, text=True)
        return jsonify(success=True, output=result.stdout)
    except Exception as e:
        return jsonify(success=False, error=str(e))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
