#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "No argument supplied"
  exit 1
fi

SECONDS=0

export subscriptionId=$1
export subnum=$2

echo "Subscription ID: ${subscriptionId}"

# global parameters
export resourceGroup="openai"

### core functions

function ding {
    msg="$1"
    echo "[$(date)]Error: $msg"
}

function ip_ping() {
    local max_attempts=5
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
      echo "$(date): ping no.$attempt..."
      output=$(curl -s ipinfo.io)
      if [ $? -eq 0 ] && ! echo "$output"|grep -q "errorMsg" ; then
        echo $output | jq -c '{ip:.ip,country:.country,city:.city}'
        break
      else
        echo "retry ping..."
        attempt=$((attempt + 1))
      fi
    done

    if [ $attempt -gt $max_attempts ]; then
      ding "max attempts exceed $max_attempts."
    fi
}

#### close content filter
# eg:
# - close_content_filter japaneast-011112213 "${modelName}" "01232131" 60
# Required global parameters:
# - subscriptionId
# - resourceGroup
function close_content_filter() {
  local accountName=$1
  local modelName=$2
  local version=$3
  local capacity=$4
  local deploymentName=$5

  #local az_domain="https://httpbin.org/anything"
  local az_domain="https://management.azure.com"
  echo "[$(date)]Close content filter for ${accountName} of ${modelName}-${version}-${capacity}..."
  curl -s -X PUT "${az_domain}/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.CognitiveServices/accounts/${accountName}/deployments/${deploymentName}?api-version=2023-10-01-preview" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $accessToken" \
    -d '{
    "sku": {
      "name": "Standard",
      "capacity": '"${capacity}"'
    },
    "properties": {
      "dynamicThrottlingEnabled": true,
      "model": {
      "format": "OpenAI",
      "name": "'"${modelName}"'",
      "version": "'"${version}"'"
      },
      "raiPolicyName":"Microsoft.Nil"
  }
  } '
  echo
}

### create account
# eg:
# - az_create_account "${region}" "${subnum}"
# Required global parameters:
# - resourceGroup
function az_create_account() {
  local region=$1
  local subnum=$2

  local openai_name="${region}-${subnum}"
  az cognitiveservices account create \
    --name "${openai_name}" \
    --resource-group "${resourceGroup}" \
    --kind "OpenAI" \
    --sku "S0" \
    --location "${region}" \
    --custom-domain "${openai_name}" \
    --yes

  if [ $? -ne 0 ]; then
    ding "Create account ${openai_name} execution failed"
  fi
}

function az_deployment() {
  local accountName=$1
  local modelName=$2
  local version=$3
  local capacity=$4
  local deploymentName=$5

  echo "[$(date)]Deployment ${deploymentName} for ${accountName} of ${modelName}-${version}-${capacity}..."
  az cognitiveservices account deployment create \
    --name "${accountName}" \
    --resource-group "${resourceGroup}" \
    --deployment-name "${deploymentName}" \
    --model-name "${modelName}" \
    --model-version "${version}" \
    --model-format OpenAI \
    --sku-capacity "${capacity}" \
    --sku-name "Standard"

  if [ $? -ne 0 ]; then
    ding "Deployment ${accountName}-${modelName}-${version}-${capacity}-${deploymentName} execution failed"
  fi
}

function az_deployment_flow() {
  local region=$1
  local subnum=$2
  local modelName=$3
  local version=$4
  local capacity=$5
  local deployName=$6

  local accountName="${region}-${subnum}"
  # 1. deployment
  az_deployment "${accountName}" "${modelName}" "${version}" "${capacity}" "${deployName}"
  # 2. close content filter
  close_content_filter "${accountName}" "${modelName}" "${version}" "${capacity}" "${deployName}"
}

function az_export_accounts() {
  local sub=$1
  local subnum=$2

  local results_file="./data/openai_accounts_${subnum}.csv"
  local results_v2_file="./data/openai_accounts_v2_${subnum}.csv"
  touch "$results_file"
  touch "$results_v2_file"

  echo "Subscription ID: ${sub}"
  az account set --subscription "${sub}"

  # 获取订阅下的所有认知服务帐户
  accounts=$(az cognitiveservices account list --subscription "${sub}" --resource-group "${resourceGroup}" -o json)

  # 遍历每个帐户并提取API密钥和部署ID
  for account in $(echo "$accounts" | jq -r '.[] | @base64'); do
    account_name=$(echo "$account" | base64 --decode | jq -r '.name')
    key_list=$(az cognitiveservices account keys list --name "$account_name" --resource-group "$resourceGroup" --subscription "$sub" -o json)
    api_key1=$(echo "$key_list" | jq -r '.key1')
    api_key2=$(echo "$key_list" | jq -r '.key2')
    location=$(echo "$account" | base64 --decode | jq -r '.location')
    endpoint=$(echo "$account" | base64 --decode | jq -r '.properties.endpoint')

    echo "$sub,$account_name,$api_key1,$api_key2,$endpoint,$location"

    # append to csv
    echo "$sub,$account_name,$api_key1,$api_key2,$endpoint,$location" >> "$results_file"
    # v2
    deployments=$(az cognitiveservices account deployment list --name "${account_name}" --resource-group ${resourceGroup} -o json)
    for deployment in $(echo "$deployments" | jq -r '.[] | @base64'); do
      deploymentName=$(echo "$deployment" | base64 --decode | jq -r '.name')
      modelName=$(echo "$deployment" | base64 --decode | jq -r '.properties.model.name')
      modelVersion=$(echo "$deployment" | base64 --decode | jq -r '.properties.model.version')
      capacity=$(echo "$deployment" | base64 --decode | jq -r '.sku.capacity')

      echo "${api_key1},${deploymentName},${modelName},${modelVersion},${capacity},${endpoint}openai/deployments/$deploymentName/chat/completions?api-version=2023-07-01-preview,${location}" >> "$results_v2_file"
    done
  done
}

function az_export_accounts_v2() {
    local sub=$1
    local subnum=$2

    echo "Subscription ID: ${sub}"
    az account set --subscription "${sub}"

    # 获取订阅下的所有认知服务帐户
    accounts=$(az cognitiveservices account list --subscription "${sub}" --resource-group "${resourceGroup}" -o json)

    # 遍历每个帐户并提取API密钥和部署ID
    for account in $(echo "$accounts" | jq -r '.[] | @base64'); do
        account_name=$(echo "$account" | base64 --decode | jq -r '.name')
        key_list=$(az cognitiveservices account keys list --name "$account_name" --resource-group "$resourceGroup" --subscription "$sub" -o json)
        api_key1=$(echo "$key_list" | jq -r '.key1')
        api_key2=$(echo "$key_list" | jq -r '.key2')
        location=$(echo "$account" | base64 --decode | jq -r '.location')
        endpoint=$(echo "$account" | base64 --decode | jq -r '.properties.endpoint')

        deployments=$(az cognitiveservices account deployment list -g "${resourceGroup}" -n "$account_name" -o json | jq -r '.[] | @base64')
        for dep in $(echo $deployments); do
            model=$(echo "$dep" | base64 -d | jq -r '(.properties.model.name + '-' + .properties.model.version)')
            capacity=$(echo "$dep" | base64 -d | jq -r '.sku.capacity')
            deploymentName=$(echo "$dep" | base64 -d | jq -r '.name')
            echo "$api_key1,$model,$capacity,${endpoint}openai/deployments/$deploymentName/chat/completions?api-version=2023-07-01-preview"

            # append to csv
            echo "$api_key1,$model,$capacity,${endpoint}openai/deployments/$deploymentName/chat/completions?api-version=2023-07-01-preview" >>./data/openai_accounts_v2_"${subnum}".csv
        done
    done
}

function az_region_deployment() {
  local region=$1
  local subnum=$2
  local config=$3
  echo "[$(date)]Processing region: ${region}-${subnum}..."
  local models=($(echo "$config" | jq -r ".$region[] | @base64"))
  for model in "${models[@]}"; do
    model_json=$(echo "$model" | base64 -d)
    modelName=$(echo "$model_json" | jq -r '.modelName')
    version=$(echo "$model_json" | jq -r '.version')
    capacity=$(echo "$model_json" | jq -r '.capacity')
    deployName=$(echo "$model_json" | jq -r '.deployName')
    # deployment
    az_deployment_flow "${region}" "${subnum}" "${modelName}" "${version}" "${capacity}" "${deployName}"
  done
}

### end core functions

default_config_json=$(cat <<EOF
{
  "AustraliaEast": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 300},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 80},
    {"deployName": "gpt-4", "modelName": "gpt-4", "version": "0613", "capacity": 40},
    {"deployName": "gpt-4-vision-preview", "modelName": "gpt-4", "version": "vision-preview", "capacity": 30}
  ],
  "CanadaEast": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 300},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 80},
    {"deployName": "gpt-4", "modelName": "gpt-4", "version": "0613", "capacity": 40}
  ],
  "SwitzerlandNorth": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 300},
    {"deployName": "gpt-4", "modelName": "gpt-4", "version": "0613", "capacity": 40},
    {"deployName": "gpt-4-32k", "modelName": "gpt-4-32k", "version": "0613", "capacity": 80},
    {"deployName": "gpt-4-vision-preview", "modelName": "gpt-4", "version": "vision-preview", "capacity": 30}
  ],
  "SwedenCentral": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 300},
    {"deployName": "gpt-4", "modelName": "gpt-4", "version": "0613", "capacity": 40},
    {"deployName": "gpt-4-turbo-2024-04-09", "modelName": "gpt-4", "version": "turbo-2024-04-09", "capacity": 150},
    {"deployName": "gpt-4-32k", "modelName": "gpt-4-32k", "version": "0613", "capacity": 80},
    {"deployName": "gpt-4-vision-preview", "modelName": "gpt-4", "version": "vision-preview", "capacity": 30}
  ],
   "FranceCentral": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 240},
    {"deployName": "gpt-4", "modelName": "gpt-4", "version": "0613", "capacity": 80},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 80},
    {"deployName": "gpt-4-32k", "modelName": "gpt-4-32k", "version": "0613", "capacity": 80}
  ],
  "southIndia": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "1106", "capacity": 120},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 150}
  ],
  "NORWAYEAST": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "1106", "capacity": 120},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 150}
  ],
  "NorthCentralUS": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 300},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "0125-Preview", "capacity": 80},
    {"deployName": "gpt-4o-2024-05-13", "modelName": "gpt-4o", "version": "2024-05-13", "capacity": 150}
  ],
   "EastUS": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 240},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "0125-Preview", "capacity": 80},
    {"deployName": "gpt-4o-2024-05-13", "modelName": "gpt-4o", "version": "2024-05-13", "capacity": 150}
  ],
  "SouthCentralUS": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0125", "capacity": 240},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "0125-Preview", "capacity": 80},
    {"deployName": "gpt-4o-2024-05-13", "modelName": "gpt-4o", "version": "2024-05-13", "capacity": 150}
  ],
   "WestUS": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "1106", "capacity": 300},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 80},
    {"deployName": "gpt-4-vision-preview", "modelName": "gpt-4", "version": "vision-preview", "capacity": 30},
    {"deployName": "gpt-4o-2024-05-13", "modelName": "gpt-4o", "version": "2024-05-13", "capacity": 150}
  ],   
   "WestUS3": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "1106", "capacity": 300},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 80},
    {"deployName": "gpt-4o-2024-05-13", "modelName": "gpt-4o", "version": "2024-05-13", "capacity": 150}
  ],
    "UKSouth": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 240},
    {"deployName": "gpt-4-1106-preview", "modelName": "gpt-4", "version": "1106-Preview", "capacity": 80}
  ],
   "EastUS2": [
    {"deployName": "gpt-35-turbo", "modelName": "gpt-35-turbo", "version": "0613", "capacity": 300},
    {"deployName": "gpt-4-turbo-2024-04-09", "modelName": "gpt-4", "version": "turbo-2024-04-09", "capacity": 80},
    {"deployName": "gpt-4o-2024-05-13", "modelName": "gpt-4o", "version": "2024-05-13", "capacity": 150}
  ]
}
EOF
)

# 开号配置
config_json=${3:-$default_config_json}

num_keys=$(echo "${config_json}" | jq '. | length')
# 判断keys的数量是否等于0
if [ "$num_keys" -eq 0 ]; then
    echo "Keys的数量为0，退出脚本。"
    exit 0
fi

echo "Config Content: $config_json"

ip_ping

# preset

az account set --subscription "${subscriptionId}"
# Create resource group
az group create --name "${resourceGroup}" --location "eastus"

# 1. 创建账号
regions=($(echo "$config_json" | jq -r 'keys[]'))
region_idx=0
for region in "${regions[@]}"; do
  echo "Create account in $region..."
  if [ $region_idx -eq 0 ]; then
     az_create_account "${region}" "${subnum}"
  else
     az_create_account "${region}" "${subnum}" &
  fi
  region_idx=$((region_idx + 1))
done

echo "Total region: ${region_idx}"

# 等待并行创建账号完成
echo "Running ${subscriptionId} create account jobs"
jobs
wait

echo "All ${subscriptionId} create account jobs done"
jobs

# shellcheck disable=SC2155
export accessToken=$(az account get-access-token --resource https://management.core.windows.net -o json | jq -r .accessToken)

# 2. 部署并关闭内容过滤
mkdir -p log
regions=($(echo "$config_json" | jq -r 'keys[]'))
for region in "${regions[@]}"; do
  az_region_deployment "$region" "$subnum" "$config_json"  >> "log/${region}.log" 2>&1 &
done

# 等待并行部署完成
echo "Running ${subscriptionId} deployment jobs"
jobs
wait

echo "All ${subscriptionId} deployment jobs done"
jobs

# 3. 导出账号
mkdir -p data
az_export_accounts "${subscriptionId}" "${subnum}"
#az_export_accounts_v2 "${subscriptionId}" "${subnum}"

ip_ping

# print elapsed time
duration=$SECONDS
echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
