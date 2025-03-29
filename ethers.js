import { ethers } from "ethers";
import abi from './CreditManagerABI.json'; // if you save it

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const contractAddress = "YOUR_DEPLOYED_CONTRACT_ADDRESS";

const creditManager = new ethers.Contract(contractAddress, abi, signer);
