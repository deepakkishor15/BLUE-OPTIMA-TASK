import boto3
import pandas as pd

# Initialize EC2 client
ec2 = boto3.client('ec2', region_name='us-east-1')  # Update region if needed

# Load the CSV file
df = pd.read_csv('tag_update.csv')  # Make sure this CSV exists

for index, row in df.iterrows():
    hostname = row['Hostname']
    new_department = row['New Department']

    # Find instance by Hostname tag
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Hostname', 'Values': [hostname]}
        ]
    )

    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            print(f"Updating {instance_id} ({hostname}) to Department: {new_department}")

            # Update Department tag
            ec2.create_tags(
                Resources=[instance_id],
                Tags=[{'Key': 'Department', 'Value': new_department}]
            )
