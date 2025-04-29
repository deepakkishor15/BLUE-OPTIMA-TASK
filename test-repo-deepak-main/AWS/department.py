import boto3
import pandas as pd

# Correct path to CSV file
csv_file = '/home/control/tag_update.csv'  # Update this path if needed

# Read CSV containing the old and new department values
df = pd.read_csv(csv_file)

# AWS EC2 client
ec2_client = boto3.client('ec2', region_name='us-east-1')  # Replace with your region

# Iterate through the rows of the CSV file and update EC2 tags
for index, row in df.iterrows():
    instance_id = row['Hostname']
    current_dept = row['Current Department']
    new_dept = row['New Department']

    # Retrieve instance by Hostname tag and update the Department tag
    response = ec2_client.describe_instances(
        Filters=[{'Name': 'tag:Hostname', 'Values': [instance_id]}]
    )

    if response['Reservations']:
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                # Check if the current Department tag matches
                tags = instance.get('Tags', [])
                for tag in tags:
                    if tag['Key'] == 'Department' and tag['Value'] == current_dept:
                        # Update the Department tag with new value
                        ec2_client.create_tags(
                            Resources=[instance['InstanceId']],
                            Tags=[{'Key': 'Department', 'Value': new_dept}]
                        )
                        print(f"Updated Department tag for {instance_id} from {current_dept} to {new_dept}")

