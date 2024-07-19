from flask import Flask, request, jsonify
import requests
import json

app = Flask(__name__)

user = "admin"
token = "11eacb254cb78e16a03937d3abf2087dc2"


@app.route('/approve', methods=['GET'])
def approve():
    jenkins_url = "${ENV,var='BUILD_URL'}/input/Input_approval/proceed"
    data = {
        "parameter": [
            {"name": "VM_Creation", "value": "Yes"},
            {"name": "Description [OPTIONAL]", "value": ""},
            {"name": "Manual IP [OPTIONAL]", "value": ""}
        ]
    }
    # URL-encode the JSON data as a string
    encoded_data = {'json': json.dumps(data)}
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    
    try:
        response = requests.post(jenkins_url, auth=(user, token), data=encoded_data, headers=headers)
        if response.status_code == 200:
            return "The job has been approved successfully.", 200
        else:
            return f"Failed to approve the job. Status Code: {response.status_code}, Response: {response.text}", 500
    except Exception as e:
        return f"An error occurred: {str(e)}", 500


@app.route('/reject', methods=['GET'])
def reject():
    jenkins_url = "${ENV,var='BUILD_URL'}/input/Input_approval/abort"
    response = requests.post(jenkins_url, auth=(user, token))
    if response.status_code == 200:
        return "The job has been rejected successfully.", 200
    else:
        return "Failed to reject the job.", 500


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
