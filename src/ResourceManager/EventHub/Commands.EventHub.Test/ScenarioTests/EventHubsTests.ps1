# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Get valid resource group name
#>
function Get-ResourceGroupName
{
    return "RGName-" + (getAssetName)	
}

<#
.SYNOPSIS
Get valid EventHub name
#>
function Get-EventHubName
{
    return "EventHub-" + (getAssetName)
}

<#
.SYNOPSIS
Get valid Namespace name
#>
function Get-NamespaceName
{
    return "Eventhub-Namespace-" + (getAssetName)
	
}

<#
.SYNOPSIS
Tests EventHubs Create List Remove operations.
#>
function EventHubsTests
{
    # Setup    
    $location = Get-Location
    $resourceGroupName = Get-ResourceGroupName
	$namespaceName = Get-NamespaceName
	$eventHubName = Get-EventHubName

	# Create Resource Group
    Write-Debug "Create resource group"    
    Write-Debug " Resource Group Name : $resourceGroupName"
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force
	
	    
    # Create EventHub Namespace
    Write-Debug "  Create new eventhub namespace"
    Write-Debug " Namespace name : $namespaceName"
    $result = New-AzureRmEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -Location $location
    Wait-Seconds 15

	# Assert
	Assert-True {$result.Name -eq $namespaceName}
	

	# get the created Eventhub Namespace 
    Write-Debug " Get the created namespace within the resource group"
    $createdNamespace = Get-AzureRmEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName
    
	# Assert 
	Assert-True {$createdNamespace.Count -eq 1}

    $found = 0
    for ($i = 0; $i -lt $createdNamespace.Count; $i++)
    {
        if ($createdNamespace[$i].Name -eq $namespaceName)
        {
            $found = 1
            Assert-AreEqual $location $createdNamespace[$i].Location
            Assert-AreEqual $resourceGroupName $createdNamespace[$i].ResourceGroupName
            Assert-AreEqual "EventHub" $createdNamespace[$i].NamespaceType
            break
        }
    }
    Assert-True {$found -eq 0} "Namespace created earlier is not found."
	

	# Create a EventHub
    Write-Debug " Create new eventHub "    
    $result = New-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $eventHubName -InputFile .\.\Resources\NewEventHub.json
	
		
    Write-Debug " Get the created Eventhub "
    $createdEventHub = Get-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result.Name

    # Assert
	Assert-True {$createdEventHub.Count -eq 1}    

	# Get the Created Eventhub
    Write-Debug " Get all the created EventHub "
    $createdEventHubList = Get-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName

    $found = 0
    for ($i = 0; $i -lt $createdEventHubList.Count; $i++)
    {
        if ($createdEventHubList[$i].Name -eq $eventHubName)
        {
            $found = $found + 1
        }

        if ($createdEventHubList[$i].Name -eq $eventHubName2)
        {
            $found = $found + 1
        }
    }

	# Assert
    Assert-True {$found -eq 0} "EventHub created earlier is not found."

	# Update the Created EventHub
    Write-Debug " Update the first EventHub "    
	$createdEventHub.MessageRetentionInDays = 4	   
    $result = Set-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $createdEventHub.Name  -EventHubObj $createdEventHub
    Wait-Seconds 15
	
	# Assert
	Assert-True {$result.MessageRetentionInDays -eq $createdEventHub.MessageRetentionInDays}


	# Cleanup
	# Delete all Created Eventhub
	Write-Debug " Delete the EventHub"
	for ($i = 0; $i -lt $createdEventHubList.Count; $i++)
	{
		$delete1 = Remove-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $createdEventHubList[$i].Name		
	}
    Write-Debug " Delete namespaces"
    Remove-AzureRmEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName

}

<#
.SYNOPSIS
Tests EventHub AuthorizationRules Create List Remove operations.
#>
function EventHubsAuthTests
{
    # Setup    
    $location =  Get-Location
	$resourceGroupName = Get-ResourceGroupName
	$namespaceName = Get-NamespaceName    
	$eventHubName = Get-EventHubName	
    $authRuleName = "TestAuthRule"

	# Create ResourceGroup
    Write-Debug " Create resource group"    
    Write-Debug "Resource group name : $resourceGroupName"
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force
	   
    # Create EventHub Namespace 
    Write-Debug " Create new Eventhub namespace"
    Write-Debug "Namespace name : $namespaceName"
    $result = New-AzureRmEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -Location $location
    Wait-Seconds 15
    
	# Assert
	Assert-True {$result.Name -eq $namespaceName}

	# Get Created NameSpace
    Write-Debug " Get the created namespace within the resource group"
    $createdNamespace = Get-AzureRmEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName
    
	# Assert
	Assert-True {$createdNamespace.Count -eq 1}
    $found = 0
    for ($i = 0; $i -lt $createdNamespace.Count; $i++)
    {
        if ($createdNamespace[$i].Name -eq $namespaceName)
        {
            $found = 1
            Assert-AreEqual $location $createdNamespace[$i].Location
            Assert-AreEqual $resourceGroupName $createdNamespace[$i].ResourceGroupName
            Assert-AreEqual "EventHub" $createdNamespace[$i].NamespaceType
            break
        }
    }

	# Assert
    Assert-True {$found -eq 0} "Namespace created earlier is not found."

	# Create New EventHub
    Write-Debug " Create new eventHub "    
    $result_eventHub = New-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $eventHubName -InputFile .\.\Resources\NewEventHub.json
	
    Write-Debug "Get the created eventHub"
    $createdEventHub = Get-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name

	# Assert
    Assert-True {$createdEventHub.Count -eq 1}

	# Create Eventhub Authorization Rule
    Write-Debug "Create a EventHub Authorization Rule"
    $result = New-AzureRmEventHubAuthorizationRules -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -InputFile .\.\Resources\NewAuthorizationRule.json

	# Assert
    Assert-AreEqual $authRuleName $result.Name
    Assert-AreEqual 2 $result.Rights.Count
    Assert-True { $result.Rights -Contains "Listen" }
    Assert-True { $result.Rights -Contains "Send" }
    Wait-Seconds 15

	# Get Created Eventhub Authorization Rule
    Write-Debug "Get created authorizationRule"
    $createdAuthRule = Get-AzureRmEventHubAuthorizationRules -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -AuthorizationRule $authRuleName

	# Assert
    Assert-AreEqual $authRuleName $createdAuthRule.Name
    Assert-AreEqual 2 $createdAuthRule.Rights.Count
    Assert-True { $createdAuthRule.Rights -Contains "Listen" }
    Assert-True { $createdAuthRule.Rights -Contains "Send" }

	# Get all Eventhub Authorization Rules
    Write-Debug "Get All eventHub AuthorizationRule"
    $result = Get-AzureRmEventHubAuthorizationRules -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name 

	# Assert
    $found = 0
    for ($i = 0; $i -lt $result.Count; $i++)
    {
        if ($result[$i].Name -eq $authRuleName)
        {
            $found = 1
            Assert-AreEqual 2 $result[$i].Rights.Count
            Assert-True { $result[$i].Rights -Contains "Listen" }
            Assert-True { $result[$i].Rights -Contains "Send" }         
            break
        }
    }
    Assert-True {$found -eq 1} "EventHub AuthorizationRule created earlier is not found."

	# Update the Eventhub Authorization Rule
    Write-Debug "Update eventHub AuthorizationRule"
	$createdAuthRule.Rights.Add("Manage")
    $updatedAuthRule = Set-AzureRmEventHubAuthorizationRules -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -SASRule $createdAuthRule
    Wait-Seconds 15

	# Assert
    Assert-AreEqual $authRuleName $updatedAuthRule.Name
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	   
    # get the Updated Eventhub Authorization Rule
    $updatedAuthRule = Get-AzureRmEventHubAuthorizationRules -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -AuthorizationRule $authRuleName
    
	# Assert
    Assert-AreEqual $authRuleName $updatedAuthRule.Name
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	
	# Get the List Keys
    Write-Debug "Get Eventhub authorizationRules connectionStrings"
    $namespaceListKeys = Get-AzureRmEventHubKeys -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -AuthorizationRule $authRuleName

    Assert-True {$namespaceListKeys.PrimaryConnectionString.Contains($updatedAuthRule.PrimaryKey)}
    Assert-True {$namespaceListKeys.SecondaryConnectionString.Contains($updatedAuthRule.SecondaryKey)}
	
	# Regentrate the Keys 
	$policyKey = "PrimaryKey"

	$namespaceRegenerateKeys = Set-AzureRmEventHubRegenerateKeys -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -AuthorizationRule $authRuleName -RegenerateKeys $policyKey
	Assert-True {$namespaceRegenerateKeys.PrimaryKey -ne $namespaceListKeys.PrimaryKey}

	$policyKey1 = "SecondaryKey"

	$namespaceRegenerateKeys1 = Set-AzureRmEventHubRegenerateKeys -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -AuthorizationRule $authRuleName -RegenerateKeys $policyKey1
	Assert-True {$namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.SecondaryKey}


	# Cleanup
    Write-Debug "Delete the created EventHub AuthorizationRule"
    $result = Remove-AzureRmEventHubAuthorizationRules -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name -AuthorizationRule $authRuleName
    
    Write-Debug "Delete the Eventhub"
    Remove-AzureRmEventHub -ResourceGroup $resourceGroupName -NamespaceName $namespaceName -EventHubName $result_eventHub.Name
    
    Write-Debug "Delete NameSpace"
    Remove-AzureRmEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName
}