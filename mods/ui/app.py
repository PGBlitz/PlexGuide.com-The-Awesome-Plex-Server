import os
from flask import Flask, render_template, request

app = Flask(__name__)

# Route for the main page
@app.route('/')
def index():
    # Directory where YML files are stored
    app_dir = "/pg/ymals/"
    
    # Get the list of folders in the /pg/ymals/ directory
    if os.path.exists(app_dir):
        folders = [folder for folder in os.listdir(app_dir) if os.path.isdir(os.path.join(app_dir, folder))]
    else:
        folders = []

    return render_template('index.html', folders=folders)

# Route to load the content of a selected YML file (assuming it's named docker-compose.yml)
@app.route('/load_yml', methods=['POST'])
def load_yml():
    selected_folder = request.form.get('folder')
    app_dir = "/pg/ymals/"

    yml_file_path = os.path.join(app_dir, selected_folder, 'docker-compose.yml')

    if os.path.exists(yml_file_path):
        with open(yml_file_path, 'r') as f:
            yml_content = f.read()
    else:
        yml_content = "YML file not found."

    return yml_content

# Route to save changes to the YML file
@app.route('/save_yml', methods=['POST'])
def save_yml():
    selected_folder = request.form.get('folder')
    yml_content = request.form.get('yml_content')
    app_dir = "/pg/ymals/"

    yml_file_path = os.path.join(app_dir, selected_folder, 'docker-compose.yml')

    try:
        with open(yml_file_path, 'w') as f:
            f.write(yml_content)
        return "YML file saved successfully."
    except Exception as e:
        return f"Error saving YML file: {str(e)}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
