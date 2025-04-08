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
            loadAchievements();
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
    
    // Update student name (you might want to fetch this from a user profile)
    document.getElementById('studentName').textContent = 'Student';
    
    // Load student stats
    loadStudentStats();
}

// Load student statistics
async function loadStudentStats() {
    try {
        // Get total credits
        const credits = await contract.methods.studentCreditToken.balanceOf(accounts[0]).call();
        document.getElementById('totalCredits').textContent = credits;
        
        // Get achievements count
        const achievementCount = await contract.methods.achievements.length().call();
        let earnedCount = 0;
        
        for (let i = 0; i < achievementCount; i++) {
            const earned = await contract.methods.earnedAchievements(accounts[0], i).call();
            if (earned) earnedCount++;
        }
        
        document.getElementById('achievementsCount').textContent = earnedCount;
    } catch (error) {
        console.error('Error loading student stats:', error);
    }
}

// Load achievements
async function loadAchievements() {
    try {
        const achievementCount = await contract.methods.achievements.length().call();
        const earnedAchievements = document.getElementById('achievementsList');
        const availableAchievements = document.getElementById('availableAchievements');
        
        earnedAchievements.innerHTML = '';
        availableAchievements.innerHTML = '';
        
        for (let i = 0; i < achievementCount; i++) {
            const achievement = await contract.methods.achievements(i).call();
            const earned = await contract.methods.earnedAchievements(accounts[0], i).call();
            
            const card = createAchievementCard(achievement, i, earned);
            
            if (earned) {
                earnedAchievements.appendChild(card);
            } else {
                availableAchievements.appendChild(card);
            }
        }
    } catch (error) {
        console.error('Error loading achievements:', error);
    }
}

// Create achievement card
function createAchievementCard(achievement, id, earned) {
    const card = document.createElement('div');
    card.className = `achievement-card ${earned ? 'earned' : 'pending'}`;
    
    const progress = earned ? 100 : 
        (achievement.threshold > 0 ? 
            Math.min(100, (parseInt(document.getElementById('totalCredits').textContent) / achievement.threshold) * 100) : 
            0);
    
    card.innerHTML = `
        <h3>${achievement.name}</h3>
        <p>${achievement.description}</p>
        <div class="progress">
            <div class="progress-bar" style="width: ${progress}%"></div>
        </div>
        <div class="status">
            ${earned ? 'Earned' : 'In Progress'}
        </div>
    `;
    
    return card;
}

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    init();
}); 