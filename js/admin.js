// Contract ABI and address
const contractABI = [/* Your contract ABI here */];
const contractAddress = '/* Your contract address here */';

let web3;
let contract;
let accounts = [];

// Initialize Web3 and contract
async function init() {
    if (window.ethereum) {
        web3 = new Web3(window.ethereum);
        try {
            accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            contract = new web3.eth.Contract(contractABI, contractAddress);
            updateUI();
        } catch (error) {
            console.error('User denied account access');
        }
    } else {
        alert('Please install MetaMask to use this application');
    }
}

// Update UI based on connected account
function updateUI() {
    const connectBtn = document.getElementById('connectWallet');
    connectBtn.textContent = `Connected: ${accounts[0].slice(0, 6)}...${accounts[0].slice(-4)}`;
    
    // Check if connected account is an admin
    checkAdminStatus();
}

// Check if connected account is an admin
async function checkAdminStatus() {
    try {
        const isAdmin = await contract.methods.achievementManagers(accounts[0]).call();
        if (!isAdmin) {
            alert('You are not authorized as an admin');
            window.location.href = 'welcome.html';
        }
    } catch (error) {
        console.error('Error checking admin status:', error);
    }
}

// Create new achievement
document.getElementById('createAchievementForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const name = document.getElementById('achievementName').value;
    const description = document.getElementById('achievementDesc').value;
    const threshold = document.getElementById('creditThreshold').value;
    const metadataURI = document.getElementById('metadataURI').value;
    
    try {
        await contract.methods.createAchievement(name, description, threshold, metadataURI)
            .send({ from: accounts[0] });
        alert('Achievement created successfully!');
        this.reset();
    } catch (error) {
        console.error('Error creating achievement:', error);
        alert('Failed to create achievement');
    }
});

// Award achievement to student
document.getElementById('awardAchievementForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const studentAddress = document.getElementById('studentAddress').value;
    const achievementId = document.getElementById('achievementSelect').value;
    
    try {
        await contract.methods.awardAchievement(studentAddress, achievementId)
            .send({ from: accounts[0] });
        alert('Achievement awarded successfully!');
        this.reset();
    } catch (error) {
        console.error('Error awarding achievement:', error);
        alert('Failed to award achievement');
    }
});

// Add manager
document.getElementById('addManager').addEventListener('click', async function() {
    const managerAddress = document.getElementById('managerAddress').value;
    
    try {
        await contract.methods.addManager(managerAddress)
            .send({ from: accounts[0] });
        alert('Manager added successfully!');
        document.getElementById('managerAddress').value = '';
    } catch (error) {
        console.error('Error adding manager:', error);
        alert('Failed to add manager');
    }
});

// Remove manager
document.getElementById('removeManager').addEventListener('click', async function() {
    const managerAddress = document.getElementById('managerAddress').value;
    
    try {
        await contract.methods.removeManager(managerAddress)
            .send({ from: accounts[0] });
        alert('Manager removed successfully!');
        document.getElementById('managerAddress').value = '';
    } catch (error) {
        console.error('Error removing manager:', error);
        alert('Failed to remove manager');
    }
});

// Load achievements into select dropdown
async function loadAchievements() {
    try {
        const achievementCount = await contract.methods.achievements.length().call();
        const select = document.getElementById('achievementSelect');
        
        for (let i = 0; i < achievementCount; i++) {
            const achievement = await contract.methods.achievements(i).call();
            const option = document.createElement('option');
            option.value = i;
            option.textContent = achievement.name;
            select.appendChild(option);
        }
    } catch (error) {
        console.error('Error loading achievements:', error);
    }
}

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    init();
    loadAchievements();
}); 