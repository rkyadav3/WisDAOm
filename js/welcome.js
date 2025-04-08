document.addEventListener('DOMContentLoaded', function() {
    createParticles();
    
    const continueBtn = document.getElementById('continue-btn');
    const welcomeScreen = document.getElementById('welcome-screen');
    const panelSelection = document.getElementById('panel-selection');
    const adminBtn = document.getElementById('admin-btn');
    const studentBtn = document.getElementById('student-btn');
    
    continueBtn.addEventListener('click', function() {
        welcomeScreen.style.display = 'none';
        panelSelection.style.display = 'block';
    });
    
    adminBtn.addEventListener('click', function() {
        window.location.href = 'admin-panel.html';
    });
    
    studentBtn.addEventListener('click', function() {
        window.location.href = 'student-dashboard.html';
    });
});

function createParticles() {
    const particlesContainer = document.getElementById('particles');
    const particleCount = 50;
    
    for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement('div');
        particle.classList.add('particle');
        
        const size = Math.random() * 4 + 2;
        particle.style.width = `${size}px`;
        particle.style.height = `${size}px`;
        
        particle.style.left = `${Math.random() * 100}%`;
        particle.style.top = `${Math.random() * 100}%`;
        
        const tx = Math.random() > 0.5 ? '+' : '-';
        const ty = Math.random() > 0.5 ? '+' : '-';
        particle.style.setProperty('--tx', `${tx}${Math.random() * 100 + 50}px`);
        particle.style.setProperty('--ty', `${ty}${Math.random() * 100 + 50}px`);
        
        const duration = Math.random() * 20 + 10;
        const delay = Math.random() * 10;
        particle.style.animation = `float ${duration}s ${delay}s infinite linear`;
        
        particlesContainer.appendChild(particle);
    }
} 